:: FnEtcEditSuite <OrgId> <SuiteId>

@ECHO OFF
SETLOCAL EnableExtensions

:: [Function(FnEtcEditSuite)]
:: [Param(OrgId: string, SuiteId: string)]
:: [Level(Suite)]
:: [Description(Opens VS Code for the root directory configured for the given SuiteId)]

:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_Error="
    IF NOT DEFINED Input_OrgId SET "Input_Error=Missing required argument <OrgId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Input_Error=Missing required argument <SuiteId>" & GOTO DESTRUCTOR
    CALL FnEtcResolveOrganization "%Input_OrgId%"
    CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
    IF ERRORLEVEL 1 GOTO DESTRUCTOR

:FUNCTION
    CALL FnEtcLogInfo %~n0 "Opening VS Code for %Input_OrgId%/%Input_SuiteId%"
    CALL code "%Output_Resolved_OrgRootPath%\%Output_Resolved_SuiteRootPath%"
    IF ERRORLEVEL 1 SET "Input_Error=Failed to open VS Code for %Input_OrgId%/%Input_SuiteId%" & GOTO DESTRUCTOR
    GOTO DESTRUCTOR

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "%Input_Error%"
    SET "Input_Error="
    SET "Input_OrgId="
    SET "Input_SuiteId="
    EXIT /B %ERRORLEVEL%
