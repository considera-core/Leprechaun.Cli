:: FnEtcDispatchOrganization <OrgId> <Command...>

@ECHO OFF
SETLOCAL EnableExtensions

:: [Function(FnEtcDispatchOrganization)]
:: [Param(OrgId, string, required)]
:: [Param(Module, string, required)]
:: [Param(Action, string, optional)]
:: [Param(KnownArg, string, optional)]
:: [Param(KnownArgs, string, optional)]
:: [Level(Root)]

:: example: considera edit suite => edit is suite level, so we need to nav to suite and then dispatch the command there instead of trying to resolve projects
:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_Module=%~2"
    SET "Input_Action=%~3"
    SET "Input_KnownArg=%~4"
    SET "Input_KnownArgs=%~5"
    SET "Input_Error="
    IF NOT DEFINED Input_OrgId SET "Input_Error=Missing required argument <OrgId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_Module SET "Input_Error=Missing required argument <Module>" & GOTO DESTRUCTOR
    IF ERRORLEVEL 1 GOTO DESTRUCTOR

:FUNCTION
    CALL FnEtcDataSuites "%Input_OrgId%"
    FOR %%S IN (!Output_Data_Suites!) DO (
        CALL FnEtcDispatchSuite "%Input_OrgId%" "%%S" "%Input_Module%" "%Input_Action%" "%Input_KnownArg%" "%Input_KnownArgs%"
        IF ERRORLEVEL 1 CALL SET "Input_Error=Failed to dispatch suite %%S" & GOTO DESTRUCTOR
    )
    :: TODO - If %Output_Resolved_FunctionLevel% == "Organization": Dispatch NOW; Else continue drill;
    :: CALL FnEtcResolveFunction "%Input_Module%" "%Input_Action%" "Organization"
    :: IF "%Output_Resolved_FunctionLevel%"=="Organization" (
    ::     CALL Fn!Input_Module!!Input_Action! "%Input_OrgId%" "%Input_KnownArg%" "%Input_KnownArgs%"
    :: ) ELSE (
    ::     CALL FnEtcDataSuites "%Input_OrgId%"
    ::     FOR %%S IN (!Output_Data_Suites!) DO (
    ::         CALL FnEtcDispatchSuite "%Input_OrgId%" "%%S" "%Input_Module%" "%Input_Action%" "%Input_KnownArg%" "%Input_KnownArgs%"
    ::         IF ERRORLEVEL 1 CALL SET "Input_Error=Failed to dispatch suite %%S" & GOTO DESTRUCTOR
    ::     )
    :: )

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "%Input_Error%"
    SET "Input_OrgId="
    SET "Input_Module="
    SET "Input_Action="
    SET "Input_KnownArg="
    SET "Input_KnownArgs="
    SET "Input_Error="
    EXIT /B %ERRORLEVEL%