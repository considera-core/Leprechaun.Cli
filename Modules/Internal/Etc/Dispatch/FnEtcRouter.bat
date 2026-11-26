:: FnEtcRouter <OrgId> <ModuleId> <ActionId> <Arg[]>                            (organization entry)
:: ^| FnEtcRouter <OrgId> <SuiteId> <ModuleId> <ActionId> <ProjectId?> <Arg[]>     (suite entry)
:: -- Looks up the function for <ModuleId> <ActionId> in Data\Functions.csv and dispatches it
:: -- by its level (see Data\Functions.md):
:: --   Organization   called once; rejected from a suite entry
:: --   Suite          called once per suite; rejected when a project is given
:: --   Project        called once per project, fanning out over what was not given
:: --   Root           internal, never dispatched
:: -- The first argument after the action is taken as the project only from a suite entry,
:: -- and only when it names a project of that suite. Every other argument goes to the
:: -- function through Output_FnEtcFlags_Args.

:: IMPORTANT! Delayed expansion rule: %var% is expanded once, when cmd parses a whole line
:: or a whole ( ... ) block. So you need !var! only when a variable is set and
:: then read inside the same block (or on the same line).

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_SuiteIdOrModuleId=%~2"
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_Module="
    SET "Input_Action="
    SET "Input_Arg="
    SET "Local_Error="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required argument <OrgId>" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteIdOrModuleId SET "Local_Error=Missing required argument <SuiteId | ModuleId>" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcResolveOrganization "%Input_OrgId%"
    IF ERRORLEVEL 1 SET "Local_Error=Unknown organization %Input_OrgId%" & GOTO :DESTRUCTOR

    REM Second token is either a suite or, from an organization entry, the module.
    REM The resolvers have no SETLOCAL and write Input_SuiteId and Input_ProjectId
    REM themselves, so both are set explicitly after each one.
    CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteIdOrModuleId%" >NUL
    IF ERRORLEVEL 1 (
        SET "Input_SuiteId="
        SET "Input_Module=%Input_SuiteIdOrModuleId%"
        SET "Input_Action=%~3"
        SET "Input_Arg=%~4"
    ) ELSE (
        SET "Input_SuiteId=%Input_SuiteIdOrModuleId%"
        SET "Input_Module=%~3"
        SET "Input_Action=%~4"
        SET "Input_Arg=%~5"
    )
    IF NOT DEFINED Input_Module SET "Local_Error=Missing required argument <ModuleId>" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_Action SET "Local_Error=Missing required argument <ActionId>" & GOTO :DESTRUCTOR
    CALL FnEtcLogInfo %~n0 "Routing request for %Input_OrgId%/%Input_SuiteId%/%Input_Module%/%Input_Action%"

    CALL FnEtcResolveFunction "%Input_Module%" "%Input_Action%"
    IF ERRORLEVEL 1 SET "Local_Error=Unknown command %Input_Module% %Input_Action%" & GOTO :DESTRUCTOR
    SET "Local_Function=%Output_Resolved_FunctionName%"
    SET "Local_Level=%Output_Resolved_FunctionLevel%"
    IF /I "%Local_Level%"=="Root" SET "Local_Error=%Local_Function% is internal and cannot be dispatched" & GOTO :DESTRUCTOR

    REM A project is only read from a suite entry, and never from something that looks like a flag.
    SET "Input_ProjectId="
    IF DEFINED Input_SuiteId IF DEFINED Input_Arg IF NOT "!Input_Arg:~0,1!"=="-" (
        CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_Arg%" >NUL
        IF ERRORLEVEL 1 (
            SET "Input_ProjectId="
        ) ELSE (
            SET "Input_ProjectId=%Input_Arg%"
        )
    )

    REM Everything after the action (and after the project, when one was given) is passed on.
    IF DEFINED Input_ProjectId (
        CALL FnEtcFlags -p "%Input_OrgId%" "%Input_SuiteId%" "%Input_Module%" "%Input_Action%" "%Input_ProjectId%" -a %*
    ) ELSE IF DEFINED Input_SuiteId (
        CALL FnEtcFlags -p "%Input_OrgId%" "%Input_SuiteId%" "%Input_Module%" "%Input_Action%" -a %*
    ) ELSE (
        CALL FnEtcFlags -p "%Input_OrgId%" "%Input_Module%" "%Input_Action%" -a %*
    )

    IF /I "%Local_Level%"=="Organization" (
        IF DEFINED Input_SuiteId SET "Local_Error=%Local_Function% is an Organization level command, call it without a suite" & GOTO :DESTRUCTOR
        CALL FnEtcDispatchOrganization "%Input_OrgId%" "%Local_Function%" "%Local_Level%"
        GOTO :DESTRUCTOR
    )
    IF /I "%Local_Level%"=="Suite" (
        IF DEFINED Input_ProjectId SET "Local_Error=%Local_Function% is a Suite level command and does not take a project (got %Input_ProjectId%)" & GOTO :DESTRUCTOR
        IF DEFINED Input_SuiteId (
            CALL FnEtcDispatchSuite "%Input_OrgId%" "%Input_SuiteId%" "%Local_Function%" "%Local_Level%"
        ) ELSE (
            CALL FnEtcDispatchOrganization "%Input_OrgId%" "%Local_Function%" "%Local_Level%"
        )
        GOTO :DESTRUCTOR
    )
    IF /I "%Local_Level%"=="Project" (
        IF DEFINED Input_ProjectId (
            CALL FnEtcDispatchProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" "%Local_Function%"
        ) ELSE IF DEFINED Input_SuiteId (
            CALL FnEtcDispatchSuite "%Input_OrgId%" "%Input_SuiteId%" "%Local_Function%" "%Local_Level%"
        ) ELSE (
            CALL FnEtcDispatchOrganization "%Input_OrgId%" "%Local_Function%" "%Local_Level%"
        )
        GOTO :DESTRUCTOR
    )
    SET "Local_Error=%Local_Function% has unknown level %Local_Level% in Functions.csv"

:DESTRUCTOR
    IF DEFINED Local_Error (
        CALL FnEtcLogError %~n0 "%Local_Error%"
        EXIT /B 1
    )
    EXIT /B %ERRORLEVEL%
