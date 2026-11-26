:: FnEtcDispatchOrganization <OrgId> <FunctionName> <Level>
:: -- Organization level functions are called once. Suite and Project level functions are
:: -- dispatched to every active suite of the organization.
:: -- Arguments for the function are read from Output_FnEtcFlags_Args (set by FnEtcRouter).

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnEtcDispatchOrganization)]
:: [Param(OrgId, string, required)]
:: [Param(FunctionName, string, required)]
:: [Param(Level, string, required)]
:: [Level(Root)]

:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_FunctionName=%~2"
    SET "Input_Level=%~3"
    SET "Local_Error="
    SET "Local_Failed="
    REM Snapshotted, and restored before every call, so a function that writes
    REM Output_FnEtcFlags_Args without SETLOCAL cannot change the next call's arguments.
    SET "Local_Args=!Output_FnEtcFlags_Args!"
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_FunctionName SET "Local_Error=Missing required parameter: FunctionName" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_Level SET "Local_Error=Missing required parameter: Level" & GOTO :DESTRUCTOR

:FUNCTION
    IF /I "%Input_Level%"=="Organization" (
        CALL %Input_FunctionName% "%Input_OrgId%" !Local_Args!
        GOTO :DESTRUCTOR
    )
    CALL FnEtcDataSuites "%Input_OrgId%"
    IF ERRORLEVEL 1 SET "Local_Error=Failed to read the suites of %Input_OrgId%" & GOTO :DESTRUCTOR
    IF NOT DEFINED Output_Data_SuitesActive SET "Local_Error=No active suites in %Input_OrgId%" & GOTO :DESTRUCTOR
    SET "Local_Suites=%Output_Data_SuitesActive%"
    FOR %%S IN (%Local_Suites%) DO (
        SET "Output_FnEtcFlags_Args=!Local_Args!"
        CALL FnEtcDispatchSuite "%Input_OrgId%" "%%S" "%Input_FunctionName%" "%Input_Level%"
        IF ERRORLEVEL 1 SET "Local_Failed=!Local_Failed! %%S"
    )
    IF DEFINED Local_Failed SET "Local_Error=Dispatch failed for suites:!Local_Failed!"

:DESTRUCTOR
    IF DEFINED Local_Error (
        CALL FnEtcLogError %~n0 "%Local_Error%"
        EXIT /B 1
    )
    EXIT /B 0
