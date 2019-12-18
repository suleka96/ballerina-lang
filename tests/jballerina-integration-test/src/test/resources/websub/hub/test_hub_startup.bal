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

import ballerina/http;
import ballerina/websub;

listener http:Listener testHub = new(23190);

service hub on testHub {
    resource function startup(http:Caller caller, http:Request request) returns error? {
        http:Listener lis0 = new (23391);
        http:Listener lis1 = new (23392);
        websub:Hub|websub:HubStartedUpError|websub:HubStartupError res =
            websub:startHub(lis0, "/websub", "/hub", "/pub", publicUrl = "https://localhost:23391");

        if (res is websub:Hub) {
            if (res.publishUrl != "https://localhost:23391/websub/pub" ||
                    res.subscriptionUrl != "https://localhost:23391/websub/hub") {
                return caller->respond("invalid publishUrl and subscriptionUrl");
            }
        } else {
            return caller->respond("hub(lis0) start up error");
        }

        // testHubStartUpWhenStarted
        websub:Hub|websub:HubStartedUpError|websub:HubStartupError res2 =
                websub:startHub(lis1);

        if !(res2 is websub:HubStartedUpError) || res2.startedUpHub !== res {
            return caller->respond("hub(lis1) start up error");
        }

        // testHubShutdownAndStart
        websub:Hub hub = <websub:Hub> res;
        error? err = hub.stop();
        if (err is error) {
            return caller->respond("hub(lis0) stop error");
        }
        err = lis0.__gracefulStop();
        err = lis1.__gracefulStop();

        http:Listener lis2 = new (23393);
        res2 = websub:startHub(lis2);
        err = lis2.__gracefulStop();
        if res2 is websub:Hub {
            string responseMsg = res2.publishUrl == "http://localhost:23393/publish" && res2.subscriptionUrl ==
                            "http://localhost:23393/" ? "hub(lis2) start successfully" :
                            "incorrect hub(lis2) has started";
            err = hub.stop();
            return caller->respond(responseMsg);
        }
        return caller->respond("hub(lis2) start up error");
    }

    resource function testPublisherAndSubscriptionInvalidSameResourcePath(http:Caller caller, http:Request request)
                                                                                                    returns error? {
        http:Listener lis = new (23394);
        websub:Hub|websub:HubStartedUpError|websub:HubStartupError res =
            websub:startHub(lis, "/websub", "/hub", "/hub");

        var err = lis.__gracefulStop();

        if (res is websub:HubStartupError) {
            //if (res.reason() == "{ballerina/websub}HubStartupError" &&
            //    res.detail().message == "publisher and subscription resource paths cannot be the same") {
            //}
            return caller->respond(res.detail().message);
        }
        return caller->respond("Unexpected result");
    }
}
