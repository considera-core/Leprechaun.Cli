:: FnEtcDispatchSuite <OrgId> <SuiteId> <Command...>

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnEtcDispatchSuite)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(Module, string, required)]
:: [Param(Action, string, optional)]
:: [Param(KnownArg, string, optional)]
:: [Param(KnownArgs, string, optional)]
:: [Level(Root)]

:: example: considera edit suite => edit is suite level, so we need to nav to suite and then dispatch the command there instead of trying to resolve projects
:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_Module=%~3"
    SET "Input_Action=%~4"
    SET "Input_KnownArg=%~5"
    SET "Input_KnownArgs=%~6"
    SET "Input_Error="
    IF NOT DEFINED Input_OrgId SET "Input_Error=Missing required argument <OrgId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Input_Error=Missing required argument <SuiteId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_Module SET "Input_Error=Missing required argument <Module>" & GOTO DESTRUCTOR
    IF ERRORLEVEL 1 GOTO DESTRUCTOR

:FUNCTION
    CALL FnEtcCacheGet Projects "[%Input_OrgId%][%Input_SuiteId%]" || CALL FnEtcDataProjects "%Input_OrgId%" "%Input_SuiteId%"
    IF DEFINED Output_Cache_Projects (
        CALL SET "Output_Data_Projects=%Output_Cache_Projects%"
    )
    FOR %%P IN (%Output_Data_Projects%) DO (
        CALL FnEtcDispatchProject "%Input_OrgId%" "%Input_SuiteId%" "%%P" "%Input_Module%" "%Input_Action%" "%Input_KnownArg%" "%Input_KnownArgs%"
        IF ERRORLEVEL 1 CALL SET "Input_Error=Failed to dispatch project %%P" & GOTO DESTRUCTOR
    )

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "%Input_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_Module="
    SET "Input_Action="
    SET "Input_KnownArg="
    SET "Input_KnownArgs="
    SET "Input_Error="
    EXIT /B %ERRORLEVEL%