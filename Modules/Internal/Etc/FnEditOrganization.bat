:: FnEditOrganization <OrgId>

@ECHO OFF
SETLOCAL EnableExtensions

:: [Function(FnEditOrganization)]
:: [Param(OrgId: string)]
:: [Level(Organization)]
:: [Description(Opens VS Code for the root directory configured for the given OrgId)]

:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_Error="
    IF NOT DEFINED Input_OrgId SET "Input_Error=Missing required argument <OrgId>" & GOTO DESTRUCTOR
    CALL FnEtcResolveOrganization "%Input_OrgId%"
    IF ERRORLEVEL 1 GOTO DESTRUCTOR

:FUNCTION
    CALL FnEtcLogInfo %~n0 "Opening VS Code for %Input_OrgId%"
    CALL code "%Output_Resolved_OrgRootPath%"
    IF ERRORLEVEL 1 SET "Input_Error=Failed to open VS Code for %Input_OrgId%" & GOTO DESTRUCTOR

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "%Input_Error%"
    SET "Input_Error="
    SET "Input_OrgId="
    EXIT /B %ERRORLEVEL%
