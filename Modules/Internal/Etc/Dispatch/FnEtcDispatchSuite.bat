:: FnEtcDispatchSuite <OrgId> <SuiteId> <FunctionName> <Level>
:: -- Suite level functions are called once. Project level functions are dispatched to every
:: -- project of the suite.
:: -- Arguments for the function are read from Output_FnEtcFlags_Args (set by FnEtcRouter).

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnEtcDispatchSuite)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(FunctionName, string, required)]
:: [Param(Level, string, required)]
:: [Level(Root)]

:CONSTRUCTOR
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_FunctionName=%~3"
    SET "Input_Level=%~4"
    SET "Local_Error="
    SET "Local_Failed="
    SET "Local_Args=!Output_FnEtcFlags_Args!"
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_FunctionName SET "Local_Error=Missing required parameter: FunctionName" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_Level SET "Local_Error=Missing required parameter: Level" & GOTO :DESTRUCTOR

:FUNCTION
    IF /I "%Input_Level%"=="Suite" (
        CALL %Input_FunctionName% "%Input_OrgId%" "%Input_SuiteId%" !Local_Args!
        GOTO :DESTRUCTOR
    )
    IF /I NOT "%Input_Level%"=="Project" SET "Local_Error=%Input_FunctionName% is %Input_Level% level and cannot run per suite" & GOTO :DESTRUCTOR

    SET "Output_Cache_Projects="
    CALL FnEtcCacheGet Projects "[%Input_OrgId%][%Input_SuiteId%]" || CALL FnEtcDataProjects "%Input_OrgId%" "%Input_SuiteId%"
    IF DEFINED Output_Cache_Projects (
        SET "Local_Projects=%Output_Cache_Projects%"
    ) ELSE (
        SET "Local_Projects=%Output_Data_Projects%"
    )
    IF NOT DEFINED Local_Projects SET "Local_Error=No projects in %Input_OrgId%/%Input_SuiteId%" & GOTO :DESTRUCTOR

    FOR %%P IN (%Local_Projects%) DO (
        SET "Output_FnEtcFlags_Args=!Local_Args!"
        CALL FnEtcDispatchProject "%Input_OrgId%" "%Input_SuiteId%" "%%P" "%Input_FunctionName%"
        IF ERRORLEVEL 1 SET "Local_Failed=!Local_Failed! %%P"
    )
    IF DEFINED Local_Failed SET "Local_Error=Dispatch failed for projects:!Local_Failed!"

:DESTRUCTOR
    IF DEFINED Local_Error (
        CALL FnEtcLogError %~n0 "%Local_Error%"
        EXIT /B 1
    )
    EXIT /B 0
