@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnNpmCoverage)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Local_Error="
    SET "Local_OutputPath=%~d0\.tmp\coverage"
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnNpmCoverage <OrgId> <SuiteId> <ProjectId> [Flags]"
        ECHO "Runs the tests with code coverage and copies coverage-summary.json to <drive>\.tmp\coverage."
        ECHO "Flags:"
        ECHO "  --here      Run in the current directory"
        ECHO "  --help      Show help information"
        VER >NUL
        GOTO :DESTRUCTOR
    )
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        CALL FnEtcResolveOrganization "%Input_OrgId%"
        CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
        CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
        CALL FnEtcResolveProjectPath
        IF ERRORLEVEL 1 SET "Local_Error=Failed to resolve project path" & GOTO :DESTRUCTOR
        IF NOT EXIST "!Output_Resolved_ProjectPath!\package.json" (
            CALL FnEtcLogInfo %~n0 "No package.json in %Input_SuiteId%/%Input_ProjectId%, skipping"
            GOTO :DESTRUCTOR
        )
        IF NOT EXIST "!Local_OutputPath!" MKDIR "!Local_OutputPath!"
        IF NOT EXIST "!Local_OutputPath!" SET "Local_Error=Could not create output directory !Local_OutputPath!" & GOTO :DESTRUCTOR

        PUSHD "!Output_Resolved_ProjectPath!"
        CALL FnEtcLogInfo %~n0 "Running tests and code coverage for %Input_SuiteId%/%Input_ProjectId%"
        REM Prefer the project's own coverage script, fall back to the Angular CLI.
        FINDSTR /C:"test:coverage" package.json >NUL 2>&1
        IF ERRORLEVEL 1 (
            CALL npx ng test --no-watch --code-coverage >NUL 2>&1
        ) ELSE (
            CALL npm run test:coverage >NUL 2>&1
        )
        IF ERRORLEVEL 1 (
            CALL FnEtcLogWarning %~n0 "Test run failed"
        ) ELSE (
            CALL FnEtcLogInfo %~n0 "Test run succeeded"
        )

        SET "Local_Summary="
        IF EXIST "coverage" FOR /R "coverage" %%F IN (coverage-summary.json) DO IF EXIST "%%F" SET "Local_Summary=%%F"
        IF NOT DEFINED Local_Summary SET "Local_Error=Coverage summary not found under !Output_Resolved_ProjectPath!\coverage. Enable the json-summary reporter" & POPD & GOTO :DESTRUCTOR

        COPY /Y "!Local_Summary!" "!Local_OutputPath!\%Input_SuiteId%-%Input_ProjectId%.json" >NUL 2>&1
        IF ERRORLEVEL 1 (
            CALL FnEtcLogWarning %~n0 "Failed to copy coverage summary"
        ) ELSE (
            CALL FnEtcLogInfo %~n0 "Output saved to !Local_OutputPath!\%Input_SuiteId%-%Input_ProjectId%.json"
        )
        POPD
    ) ELSE (
        CALL FnEtcRunInNewTab "FnNpmCoverage %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Local_OutputPath="
    SET "Local_Summary="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
