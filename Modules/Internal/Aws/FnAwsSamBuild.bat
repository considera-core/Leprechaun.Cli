@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnAwsSamBuild)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Flag(--prod, Use samconfig.prod.toml instead of samconfig.dev.toml)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Local_Error="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnAwsSamBuild <OrgId> <SuiteId> <ProjectId> [Flags]"
        ECHO "Runs 'sam build'. Only needed for Lambda functions. Projects without a template.yaml are skipped."
        ECHO "Flags:"
        ECHO "  --here      Run in the current directory"
        ECHO "  --prod      Use samconfig.prod.toml instead of samconfig.dev.toml"
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
        IF NOT EXIST "!Output_Resolved_ProjectPath!\template.yaml" (
            CALL FnEtcLogInfo %~n0 "No template.yaml in %Input_SuiteId%/%Input_ProjectId%, skipping"
            GOTO :DESTRUCTOR
        )
        WHERE sam >NUL 2>&1
        IF ERRORLEVEL 1 SET "Local_Error=sam CLI not found on PATH. Install it with: winget install Amazon.SAM-CLI" & GOTO :DESTRUCTOR

        SET "Local_ConfigArgs="
        CALL FnEtcFlagsContains --prod
        IF ERRORLEVEL 1 (
            IF EXIST "!Output_Resolved_ProjectPath!\samconfig.prod.toml" SET "Local_ConfigArgs=--config-file samconfig.prod.toml"
        ) ELSE (
            IF EXIST "!Output_Resolved_ProjectPath!\samconfig.dev.toml" SET "Local_ConfigArgs=--config-file samconfig.dev.toml"
        )

        CALL FnEtcLogInfo %~n0 "Building %Input_SuiteId%/%Input_ProjectId% !Local_ConfigArgs!"
        PUSHD "!Output_Resolved_ProjectPath!"
        CALL sam build !Local_ConfigArgs!
        IF ERRORLEVEL 1 SET "Local_Error=sam build failed for %Input_SuiteId%/%Input_ProjectId%" & POPD & GOTO :DESTRUCTOR
        POPD
    ) ELSE (
        CALL FnEtcRunInNewTab "FnAwsSamBuild %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Local_ConfigArgs="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
