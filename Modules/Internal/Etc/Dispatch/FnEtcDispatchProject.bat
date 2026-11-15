:: FnEtcDispatchProject <OrgId> <SuiteId> <ProjectId> <Command...>

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnEtcDispatchProject)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Module, string, required)]
:: [Param(Action, string, optional)]
:: [Param(KnownArg, string, optional)]
:: [Param(KnownArgs, string, optional)]
:: [Level(Root)]

:: example: considera edit suite => edit is suite level, so we need to nav to suite and then dispatch the command there instead of trying to resolve projects
:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_Module=%~4"
    SET "Input_Action=%~5"
    SET "Input_KnownArg=%~6"
    SET "Input_KnownArgs=%~7"
    SET "Input_Error="
    IF NOT DEFINED Input_OrgId SET "Input_Error=Missing required argument <OrgId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Input_Error=Missing required argument <SuiteId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Input_Error=Missing required argument <ProjectId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_Module SET "Input_Error=Missing required argument <Module>" & GOTO DESTRUCTOR
    IF ERRORLEVEL 1 GOTO DESTRUCTOR

:FUNCTION
    :: The router already parsed the extra arguments into Output_FnEtcFlags_Args, with each
    :: token's own quotes kept, so pass them on as separate arguments. Wrapping them in one
    :: more pair of quotes broke any argument that contains a space ("my message").
    SET "Local_Lead="
    IF DEFINED Input_KnownArg SET "Local_Lead="%Input_KnownArg%""
    IF DEFINED Output_FnEtcFlags_Args (
        CALL Fn%Input_Module%%Input_Action% "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" !Local_Lead! !Output_FnEtcFlags_Args!
    ) ELSE (
        CALL Fn%Input_Module%%Input_Action% "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" "%Input_KnownArg%" "%Input_KnownArgs%"
    )
    IF ERRORLEVEL 1 CALL SET "Input_Error=Failed to dispatch project %Input_ProjectId%" & GOTO DESTRUCTOR

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "%Input_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_Module="
    SET "Input_Action="
    SET "Input_KnownArg="
    SET "Input_KnownArgs="
    SET "Input_Error="
    EXIT /B %ERRORLEVEL%