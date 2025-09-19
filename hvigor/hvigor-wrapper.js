/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');

const HVIGOR_BOOT_JS_FILE_PATH = path.resolve(__dirname, 'hvigor-boot.js');
const HVIGOR_BOOT_JS_FILE_URL = 'https://repo.harmonyos.com/harmonyos/os/1.0.0/platform/hvigor-boot.js';

if (!fs.existsSync(HVIGOR_BOOT_JS_FILE_PATH)) {
    console.log('Downloading hvigor-boot.js...');
    try {
        execSync(`curl -o "${HVIGOR_BOOT_JS_FILE_PATH}" "${HVIGOR_BOOT_JS_FILE_URL}"`, { stdio: 'inherit' });
    } catch (error) {
        console.error('Failed to download hvigor-boot.js');
        process.exit(1);
    }
}

require(HVIGOR_BOOT_JS_FILE_PATH);