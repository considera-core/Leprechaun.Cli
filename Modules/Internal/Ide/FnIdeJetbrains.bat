@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnIdeJetbrains)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Flag(--debug, Attach the Rider debugger to the running process instead of opening the IDE)]
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
        ECHO "Usage: FnIdeJetbrains <OrgId> <SuiteId> <ProjectId> [Flags]"
        ECHO "Opens the JetBrains IDE for the project type: WebStorm for Client projects, Rider otherwise."
        ECHO "Flags:"
        ECHO "  --here      Run in the current directory"
        ECHO "  --debug     Attach the Rider debugger to the running process instead of opening the IDE"
        ECHO "  --help      Show help information"
        VER >NUL
        GOTO :DESTRUCTOR
    )
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        CALL FnEtcFlagsContains --debug
        IF ERRORLEVEL 1 (
            CALL FnIdeRiderDebug "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" --here
            GOTO :DESTRUCTOR
        )
        CALL FnEtcResolveOrganization "%Input_OrgId%"
        CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
        CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
        IF ERRORLEVEL 1 SET "Local_Error=Failed to resolve project %Input_SuiteId%/%Input_ProjectId%" & GOTO :DESTRUCTOR
        IF /I "!Output_Resolved_ProjectType!"=="Client" (
            CALL FnIdeWebstorm "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
        ) ELSE (
            CALL FnIdeRider "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
        )
    ) ELSE (
        CALL FnEtcRunInNewTab "FnIdeJetbrains %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
