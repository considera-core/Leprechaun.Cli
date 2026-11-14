:: FnEtcDispatch <EntryId> <Command...>                     when <EntryId> is Global
:: FnEtcDispatch <EntryId> <ValueId> <Command...>            otherwise

:: FnEtcDispatch <Scope>
:: ^| FnEtcDispatch global         (all organizations, suites and projects)
:: ^| FnEtcDispatch organization   (all suites and projects in the organization)
:: ^| FnEtcDispatch suite          (all projects in the suite)
:: ^| FnEtcDispatch project        (the specific project)

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:CONSTRUCTOR
    SET "Input_Scope=%~1"
    IF NOT DEFINED Input_Scope set "Input_Error=Missing required argument ^<Scope^>" & GOTO DESTRUCTOR

:FUNCTION
    IF /I "%Input_Scope%"=="global" (
        CALL FnEtcDispatchGlobal "%Input_Command%"
        IF ERRORLEVEL 1 SET "Input_Error=Dispatch via global failed"
        GOTO DESTRUCTOR
    )
    IF /I "%Input_Scope%"=="organization" (
        CALL FnEtcDispatchOrganization "%~2" "%~3" "%~4" "%~5" "%~6"
        IF ERRORLEVEL 1 SET "Input_Error=Dispatch via organization failed"
        GOTO DESTRUCTOR
    ) 
    IF /I "%Input_Scope%"=="suite" (
        CALL FnEtcDispatchSuite "%~2" "%~3" "%~4" "%~5" "%~6" "%~7"
        IF ERRORLEVEL 1 SET "Input_Error=Dispatch via suite failed"
        GOTO DESTRUCTOR
    )
    IF /I "%Input_Scope%"=="project" (
        CALL FnEtcDispatchProject "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8"
        IF ERRORLEVEL 1 SET "Input_Error=Dispatch via project failed"
        GOTO DESTRUCTOR
    )
    SET "Input_Error=Unknown scope %Input_Scope%"
    CALL FnEtcLogError %~n0 "Unknown scope %Input_Scope%. Expected global, organization, suite, project"

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "%Input_Error%"
    SET "Input_Scope="
    SET "Input_Error="
    EXIT /B %ERRORLEVEL%