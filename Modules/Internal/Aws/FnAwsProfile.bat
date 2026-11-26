@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnAwsProfile)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Flag(--prod, Use the production AWS profile (appends _prod to name))]
:: [Level(Suite)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Local_Error="
    SET "Local_Profile=%~2"
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnAwsProfile <OrgId> <SuiteId> [Flags]"
        ECHO "Flags:"
        ECHO "  --here      Run in the current directory"
        ECHO "  --prod      Use the production AWS profile (appends _prod to name)"
        ECHO "  --help      Show help information"
        VER >NUL
        GOTO :DESTRUCTOR
    )
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        CALL FnEtcResolveOrganization "%Input_OrgId%"
        CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
        IF ERRORLEVEL 1 SET "Local_Error=Failed to resolve suite %Input_SuiteId%" & GOTO :DESTRUCTOR
        CALL FnEtcFlagsContains --prod
        IF ERRORLEVEL 1 SET "Local_Profile=!Local_Profile!_prod"
        SETX AWS_PROFILE "!Local_Profile!" >NUL
        SET "AWS_PROFILE=!Local_Profile!"
        CALL FnEtcLogInfo %~n0 "AWS_PROFILE set to !Local_Profile!"
        CALL FnEtcLogInfo %~n0 "Updated for future sessions. Open a new terminal, or run refreshenv, to pick it up"
    ) ELSE (
        CALL FnEtcRunInNewTab "FnAwsProfile %Input_OrgId% %Input_SuiteId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Local_Profile="
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
