// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/filepath;
import ballerina/http;
import ballerina/io;
import ballerina/system;

const int MAX_INT_VALUE = 2147483647;
const string VERSION_REGEX = "(\\d+\\.)(\\d+\\.)(\\d+)";

DefaultLogFormatter logFormatter = new DefaultLogFormatter();
boolean isBuild = false;

# This object denotes the default log formatter used when pulling a module directly.
#
# + offset - Offset from the terminal width.
type DefaultLogFormatter object {
    int offset = 0;
    function formatLog(string msg) returns string {
        return msg;
    }
};

# This object denotes the build log formatter used when pulling a module while building.
#
# + offset - Offset from the terminal width.
type BuildLogFormatter object {
    int offset = 10;
    function formatLog(string msg) returns string {
        return "\t" + msg;
    }
};

# Creates an error record.

# + errMessage - The error message.
# + return - Newly created error record.
function createError(string errMessage) returns error {
    error endpointError = error(logFormatter.formatLog(errMessage));
    return endpointError;
}

# This function pulls a module from ballerina central.
#
# + args - Arguments for pulling a module
public function main(string... args) {
    http:Client httpEndpoint;
    string url = <@untainted> args[0];
    string modulePathInBaloCache = args[1]; // <user.home>.ballerina/balo_cache/<org-name>/<module-name>/<version>/ . if no version given then uses "*".
    string modulePath = <@untainted> args[2]; // <org-name>/<module-name>
    string host = args[3];
    string strPort = args[4];
    string proxyUsername = args[5];
    string proxyPassword = args[6];
    string terminalWidth = args[7];
    string versionRange = args[8];
    isBuild = <@untainted> boolean.convert(args[9]);
    boolean nightlyBuild = <@untainted> boolean.convert(args[10]);

    if (isBuild) {
        logFormatter = new BuildLogFormatter();
    }

    if (host != "" && strPort != "") {
        // validate port
        int|error port = int.convert(strPort);
        if (port is error) {
            panic createError("invalid port : " + strPort);
        } else {
            http:Client|error result = trap defineEndpointWithProxy(url, host, port, proxyUsername, proxyPassword);
            if (result is error) {
                panic createError("failed to resolve host : " + host + " with port " + port);
            } else {
                httpEndpoint = result;
                return pullPackage(httpEndpoint, url, modulePath, modulePathInBaloCache, versionRange, terminalWidth, nightlyBuild);
            }
        }
    } else if (host != "" || strPort != "") {
        panic createError("both host and port should be provided to enable proxy");
    } else {
        httpEndpoint = defineEndpointWithoutProxy(url);
        return pullPackage(httpEndpoint, url, modulePath, modulePathInBaloCache, versionRange, terminalWidth, nightlyBuild);
    }
}

# Pulling a module.
#
# + httpEndpoint - The endpoint to call
# + url - Central URL
# + modulePath - Module Path.
# + baloCache - Balo cache path.
# + versionRange - Balo version range.
# + terminalWidth - Width of the terminal
# + nightlyBuild - Release is a nightly build
function pullPackage(http:Client httpEndpoint, string url, string modulePath, string baloCache, string versionRange,
                     string terminalWidth, boolean nightlyBuild) {
    http:Client centralEndpoint = httpEndpoint;

    http:Request req = new;
    req.addHeader("Accept-Encoding", "identity");
    http:Response|error httpResponse = centralEndpoint->get(<@untainted> versionRange, message=req);
    if (httpResponse is error) {
        panic createError("connection to the remote host failed : " + <string>httpResponse.detail().msg);
    } else {
        string statusCode = string.convert(httpResponse.statusCode);
        if (statusCode.hasPrefix("5")) {
            panic createError("remote registry failed for url:" + url);
        } else if (statusCode != "200") {
            var resp = httpResponse.getJsonPayload();
            if (resp is json) {
                if (statusCode == "404" && isBuild && resp.message.toString().contains("module not found")) {
                    // To ignore printing the error
                    panic createError("");
                } else {
                    panic createError(resp.message.toString());
                }
            } else {
                panic createError("error occurred when pulling the module");
            }
        } else {
            string contentLengthHeader;
            int baloSize = <@untainted> MAX_INT_VALUE;

            if (httpResponse.hasHeader("content-length")) {
                contentLengthHeader = httpResponse.getHeader("content-length");
                baloSize = <@untainted> checkpanic int.convert(contentLengthHeader);
            } else {
                panic createError("module size information is missing from remote repository. please retry.");
            }

            io:ReadableByteChannel sourceChannel = checkpanic (httpResponse.getByteChannel());

            string resolvedURI = httpResponse.resolvedRequestedURI;
            if (resolvedURI == "") {
                resolvedURI = url;
            }

            string [] uriParts = resolvedURI.split("/");
            string moduleVersion = uriParts[uriParts.length() - 3];
            boolean valid = checkpanic moduleVersion.matches(VERSION_REGEX);

            if (valid) {
                string moduleName = modulePath.substring(modulePath.lastIndexOf("/") + 1, modulePath.length());
                string baloFile = moduleName + ".balo";

                // adding version to the module path
                string modulePathWithVersion = modulePath + ":" + moduleVersion;
                string baloCacheWithModulePath = checkpanic filepath:build(baloCache, moduleVersion); // <user.home>.ballerina/balo_cache/<org-name>/<module-name>/<module-version>

                string baloPath = checkpanic filepath:build(baloCacheWithModulePath, baloFile);
                if (system:exists(baloPath)) {
                    panic createError("module already exists in the home repository");
                }

                string|error createBaloFile = system:createDir(baloCacheWithModulePath, parentDirs = true);
                if (createBaloFile is error) {
                    panic createError("error creating directory for balo file");
                }

                io:WritableByteChannel wch = checkpanic io:openWritableFile(<@untainted> baloPath);

                string toAndFrom = " [central.ballerina.io -> home repo]";
                int rightMargin = 3;
                int width = (checkpanic int.convert(terminalWidth)) - rightMargin;
                copy(baloSize, sourceChannel, wch, modulePathWithVersion, toAndFrom, width);

                var destChannelClose = wch.close();
                if (destChannelClose is error) {
                    panic createError("error occurred while closing the channel: " + destChannelClose.reason());
                } else {
                    var srcChannelClose = sourceChannel.close();
                    if (srcChannelClose is error) {
                        panic createError("error occurred while closing the channel: " + srcChannelClose.reason());
                    } else {
                        if (nightlyBuild) {
                            // If its a nightly build tag the file as a module from nightly
                            string nightlyBuildMetafile = checkpanic filepath:build(baloCache, "nightly.build");
                            string|error createdNightlyBuildFile = system:createFile(nightlyBuildMetafile);
                            if (createdNightlyBuildFile is error) {
                                panic createError("Error occurred while creating nightly.build file.");
                            }
                        }
                        return ();
                    }
                }
            } else {
                panic createError("module version could not be detected");
            }
        }
    }
}

# This function defines an endpoint with proxy configurations.
#
# + url - URL to be invoked
# + hostname - Host name of the proxy
# + port - Port of the proxy
# + username - Username of the proxy
# + password - Password of the proxy
# + return - Endpoint defined
public function defineEndpointWithProxy(string url, string hostname, int port, string username, string password) returns http:Client {
    http:Client httpEndpointWithProxy = new(url, config = {
        secureSocket:{
            trustStore:{
                path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
                password: "ballerina"
            },
            verifyHostname: false,
            shareSession: true
        },
        followRedirects: { enabled: true, maxCount: 5 },
        proxy : getProxyConfigurations(hostname, port, username, password)
    });
    return <@untainted> httpEndpointWithProxy;
}

# This function defines an endpoint without proxy configurations.
#
# + url - URL to be invoked
# + return - Endpoint defined
function defineEndpointWithoutProxy(string url) returns http:Client{
    http:Client httpEndpointWithoutProxy = new(url, config = {
        secureSocket:{
            trustStore:{
                path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
                password: "ballerina"
            },
            verifyHostname: false,
            shareSession: true
        },
        followRedirects: { enabled: true, maxCount: 5 }
    });
    return <@untainted> httpEndpointWithoutProxy;
}

# This function will read the bytes from the byte channel.
#
# + byteChannel - Byte channel
# + numberOfBytes - Number of bytes to be read
# + return - Read content as byte[] along with the number of bytes read, or error if read failed
function readBytes(io:ReadableByteChannel byteChannel, int numberOfBytes) returns [byte[], int]|error {
    byte[] bytes;
    int numberOfBytesRead;
    [bytes, numberOfBytesRead] = check (byteChannel.read(numberOfBytes));
    return <@untainted>[bytes, numberOfBytesRead];
}

# This function will write the bytes from the byte channel.
#
# + byteChannel - Byte channel
# + content - Content to be written as a byte[]
# + startOffset - Offset
# + return - number of bytes written.
function writeBytes(io:WritableByteChannel byteChannel, byte[] content, int startOffset) returns int|error {
    int numberOfBytesWritten = check (byteChannel.write(content, startOffset));
    return numberOfBytesWritten;
}

# This function will copy files from source to the destination path.
#
# + baloSize - Size of the module pulled
# + src - Byte channel of the source file
# + dest - Byte channel of the destination folder
# + modulePath - Full module path
# + toAndFrom - Pulled module details
# + width - Width of the terminal
function copy(int baloSize, io:ReadableByteChannel src, io:WritableByteChannel dest,
              string modulePath, string toAndFrom, int width) {
    int terminalWidth = width - logFormatter.offset;
    int bytesChunk = 8;
    byte[] readContent = [];
    int readCount = -1;
    float totalCount = 0.0;
    int numberOfBytesWritten = 0;
    string noOfBytesRead;
    string equals = "==========";
    string tabspaces = "          ";
    boolean completed = false;
    int rightMargin = 5;
    int totalVal = 10;
    int startVal = 0;
    int rightpadLength = terminalWidth - equals.length() - tabspaces.length() - rightMargin;
    while (!completed) {
        [readContent, readCount] = checkpanic readBytes(src, bytesChunk);
        if (readCount <= startVal) {
            completed = true;
        }
        if (dest != ()) {
            numberOfBytesWritten = checkpanic writeBytes(dest, readContent, startVal);
        }
        totalCount = totalCount + readCount;
        float percentage = totalCount / baloSize;
        noOfBytesRead = totalCount + "/" + baloSize;
        string bar = equals.substring(startVal, <int> (percentage * totalVal));
        string spaces = tabspaces.substring(startVal, totalVal - <int>(percentage * totalVal));
        string size = "[" + bar + ">" + spaces + "] " + <int>totalCount + "/" + baloSize;
        string msg = truncateString(modulePath + toAndFrom, terminalWidth - size.length());
        io:print("\r" + logFormatter.formatLog(rightPad(msg, rightpadLength) + size));
    }
    io:println("\r" + logFormatter.formatLog(rightPad(modulePath + toAndFrom, terminalWidth)));
    return;
}

# This function adds the right pad.
#
# + logMsg - Log message to be printed
# + logMsgLength - Length of the log message
# + return - The log message to be printed after adding the right pad
function rightPad (string logMsg, int logMsgLength) returns (string) {
    string msg = logMsg;
    int length = logMsgLength;
    int i = -1;
    length = length - msg.length();
    string char = " ";
    while (i < length) {
        msg = msg + char;
        i = i + 1;
    }
    return msg;
}

# This function truncates the string.
#
# + text - String to be truncated
# + maxSize - Maximum size of the log message printed
# + return - Truncated string.
function truncateString (string text, int maxSize) returns (string) {
    int lengthOfText = text.length();
    if (lengthOfText > maxSize) {
        int endIndex = 3;
        if (maxSize > endIndex) {
            endIndex = maxSize - endIndex;
        }
        string truncatedStr = text.substring(0, endIndex);
        return truncatedStr + "…";
    }
    return text;
}

# This function will close the byte channel.
#
# + byteChannel - Byte channel to be closed
function closeChannel(io:ReadableByteChannel|io:WritableByteChannel byteChannel) {
    if (byteChannel is io:ReadableByteChannel) {
        var channelCloseError = byteChannel.close();
        if (channelCloseError is error) {
            io:println(logFormatter.formatLog("Error occured while closing the channel: " + channelCloseError.reason()));
        } else {
            return;
        }
    } else  {
        var channelCloseError = byteChannel.close();
        if (channelCloseError is error) {
            io:println(logFormatter.formatLog("Error occured while closing the channel: " + channelCloseError.reason()));
        } else {
            return;
        }
    }
}

# This function sets the proxy configurations for the endpoint.
#
# + hostName - Host name of the proxy
# + port - Port of the proxy
# + username - Username of the proxy
# + password - Password of the proxy
# + return - Proxy configurations for the endpoint
function getProxyConfigurations(string hostName, int port, string username, string password) returns http:ProxyConfig {
    http:ProxyConfig proxy = { host : hostName, port : port , userName: username, password : password };
    return proxy;
}
