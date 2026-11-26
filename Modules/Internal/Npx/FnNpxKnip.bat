@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnNpxKnip)]
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
    SET "Local_OutputPath=%~d0\.tmp\knip"
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnNpxKnip <OrgId> <SuiteId> <ProjectId> [Flags]"
        ECHO "Runs 'knip --dependencies' and saves the report to <drive>\.tmp\knip."
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

        CALL FnEtcLogInfo %~n0 "Running knip for %Input_SuiteId%/%Input_ProjectId%"
        PUSHD "!Output_Resolved_ProjectPath!"
        CALL npx -y knip --dependencies > "!Local_OutputPath!\%Input_SuiteId%-%Input_ProjectId%.txt" 2>&1
        POPD
        CALL FnEtcLogInfo %~n0 "Output saved to !Local_OutputPath!\%Input_SuiteId%-%Input_ProjectId%.txt"
    ) ELSE (
        CALL FnEtcRunInNewTab "FnNpxKnip %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Local_OutputPath="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
