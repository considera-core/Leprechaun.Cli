:: FnEtcDispatchProject <OrgId> <SuiteId> <ProjectId> <FunctionName>
:: -- Calls a Project level function for one project.
:: -- Arguments for the function are read from Output_FnEtcFlags_Args (set by FnEtcRouter).
:: -- They are passed on as separate arguments with each token's own quotes kept, so an
:: -- argument that contains a space ("my message") stays one argument.

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnEtcDispatchProject)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(FunctionName, string, required)]
:: [Level(Root)]

:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_FunctionName=%~4"
    SET "Local_Error="
    SET "Local_Args=!Output_FnEtcFlags_Args!"
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_FunctionName SET "Local_Error=Missing required parameter: FunctionName" & GOTO :DESTRUCTOR

:FUNCTION
    CALL %Input_FunctionName% "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" !Local_Args!
    IF ERRORLEVEL 1 SET "Local_Error=%Input_FunctionName% failed for %Input_SuiteId%/%Input_ProjectId%"

:DESTRUCTOR
    IF DEFINED Local_Error (
        CALL FnEtcLogError %~n0 "%Local_Error%"
        EXIT /B 1
    )
    EXIT /B 0
