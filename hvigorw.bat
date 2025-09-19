@echo off
rem Copyright (c) 2023 Huawei Device Co., Ltd.
rem Licensed under the Apache License, Version 2.0 (the "License");
rem you may not use this file except in compliance with the License.
rem You may obtain a copy of the License at
rem
rem     http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.

setlocal enabledelayedexpansion

set HVIGOR_APP_HOME=%~dp0
set HVIGOR_WRAPPER_SCRIPT=%HVIGOR_APP_HOME%hvigor\hvigor-wrapper.js

for %%i in (node.exe) do set NODE_EXE=%%~$PATH:i
if not defined NODE_EXE (
    echo.
    echo ERROR: Node.js is not installed.
    echo.
    exit /b 1
)

if not exist "%HVIGOR_WRAPPER_SCRIPT%" (
    echo.
    echo ERROR: Hvigor wrapper script not found at %HVIGOR_WRAPPER_SCRIPT%
    echo.
    exit /b 1
)

"%NODE_EXE%" "%HVIGOR_WRAPPER_SCRIPT%" %*