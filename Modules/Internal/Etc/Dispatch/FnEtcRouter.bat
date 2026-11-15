:: FnEtcRouter <OrgId> <SuiteId> <ModuleId> <ActionId> <ProjectId | Arg> <...Args?> <...Flags?>
:: ^| FnEtcRouter <OrgId> <ModuleId> <ActionId> <ProjectId | Arg> <...Args?> <...Flags?>
:: -- Also validates the existence of the params if related to Data, so no need to check again in the action level

:: IMPORTANT! Delayed expansion rule: %var% is expanded once, when cmd parses a whole line
:: or a whole ( ... ) block. So you need !var! only when a variable is set and
:: then read inside the same block (or on the same line). Variables set before
:: the block starts are fine with %var%.
:: Everything from line 32 to line 68 is inside IF ... ( ... ) blocks, so most
:: of the fixes are there.

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_SuiteIdOrModuleId=%~2"
    IF NOT DEFINED Input_OrgId SET "Input_Error=Missing required argument ^<OrgId^>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_SuiteIdOrModuleId SET "Input_Error=Missing required argument ^<SuiteId | ModuleId^>" & GOTO DESTRUCTOR
    IF ERRORLEVEL 1 GOTO DESTRUCTOR

:FUNCTION
    CALL FnEtcLogInfo %~n0 "Routing request for %Input_OrgId%/%Input_SuiteIdOrModuleId%/%~3/%~4"
    CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteIdOrModuleId%"
    IF ERRORLEVEL 1 (
        SET "Input_Module=%Input_SuiteIdOrModuleId%"
        SET "Input_Action=%~3"
        SET "Input_Arg=%~4"
        IF NOT DEFINED Input_Action SET "Input_Error=Missing required argument ^<ActionId^>" & GOTO DESTRUCTOR
        IF DEFINED Input_Arg (
            CALL FnEtcFlags -p "%Input_OrgId%" "!Input_Module!" "!Input_Action!" "!Input_Arg!" -a %*
            CALL FnEtcDispatchOrganization "%Input_OrgId%" "!Input_Module!" "!Input_Action!" "!Input_Arg!" "!Output_FnEtcFlags_Args!"
            IF ERRORLEVEL 1 SET "Input_Error=Dispatch via organization with arg failed" & GOTO DESTRUCTOR
        ) ELSE (
            CALL FnEtcFlags -p "%Input_OrgId%" "!Input_Module!" "!Input_Action!" -a %*
            CALL FnEtcDispatchOrganization "%Input_OrgId%" "!Input_Module!" "!Input_Action!" "!Output_FnEtcFlags_Args!"
            IF ERRORLEVEL 1 SET "Input_Error=Dispatch via organization without arg failed" & GOTO DESTRUCTOR
        )
    ) ELSE (
        SET "Input_SuiteId=%Input_SuiteIdOrModuleId%"
        SET "Input_Module=%~3"
        SET "Input_Action=%~4"
        SET "Input_Arg=%~5"
        IF NOT DEFINED Input_Module SET "Input_Error=Missing required argument ^<ModuleId^>" & GOTO DESTRUCTOR
        IF NOT DEFINED Input_Action SET "Input_Error=Missing required argument ^<ActionId^>" & GOTO DESTRUCTOR
        IF DEFINED Input_Arg (
            CALL FnEtcFlags -p "%Input_OrgId%" "!Input_SuiteId!" "!Input_Module!" "!Input_Action!" "!Input_Arg!" -a %*
            CALL FnEtcResolveProject "%Input_OrgId%" "!Input_SuiteId!" "!Input_Arg!"
            IF NOT DEFINED Output_Resolved_ProjectId (
                CALL FnEtcDispatchSuite "%Input_OrgId%" "!Input_SuiteId!" "!Input_Module!" "!Input_Action!" "!Input_Arg!"
                IF ERRORLEVEL 1 SET "Input_Error=Dispatch via suite with arg failed" & GOTO DESTRUCTOR
            ) ELSE (
                CALL FnEtcDispatchProject "%Input_OrgId%" "!Input_SuiteId!" "!Output_Resolved_ProjectId!" "!Input_Module!" "!Input_Action!"
                IF ERRORLEVEL 1 SET "Input_Error=Dispatch via project with arg failed" & GOTO DESTRUCTOR
            )
        ) ELSE (
            CALL FnEtcDispatchSuite "%Input_OrgId%" "!Input_SuiteId!" "!Input_Module!" "!Input_Action!"
            IF ERRORLEVEL 1 SET "Input_Error=Dispatch via suite without arg failed" & GOTO DESTRUCTOR
        )
    )

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "%Input_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_Module="
    SET "Input_Action="
    SET "Input_Arg="
    SET "Input_Error="
    EXIT /B 0
