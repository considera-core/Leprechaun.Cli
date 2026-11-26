@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnGitPush)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--here, Run in the current directory)]
:: [Level(Project)]

:CONSTRUCTOR

:FUNCTION

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    EXIT /B %ERRORLEVEL%