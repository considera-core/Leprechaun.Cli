
@ECHO OFF
SETLOCAL EnableExtensions

:CONSTRUCTOR

:FUNCTION

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    EXIT /B %ERRORLEVEL%