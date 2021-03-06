/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.openapi.test;

import org.ballerinalang.test.context.BMainInstance;
import org.ballerinalang.test.context.BallerinaTestException;
import org.ballerinalang.test.context.LogLeecher;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

/**
 * Test class to test openapi annotation enable validating.
 */
public class OpenapiValidatorOn extends BaseTestCase {
    private BMainInstance balClient;
    private String projectPath;

    @BeforeClass(enabled = false)
    public void setup() throws BallerinaTestException {
        balClient = new BMainInstance(balServer);
        projectPath = basicTestsProjectPath.toString();
    }
    @Test(enabled = false)
    public void testOpenapiValidatorOn() throws BallerinaTestException {

        String msg = "error: openapi-test/openapi-validator-on:";

        LogLeecher clientLeecher = new LogLeecher(msg, LogLeecher.LeecherType.ERROR);
        balClient.runMain("build", new String[]{ "openapi-validator-on"}, null, new String[]{},
                new LogLeecher[]{clientLeecher}, projectPath);
        clientLeecher.waitForText(20000);


    }
}
