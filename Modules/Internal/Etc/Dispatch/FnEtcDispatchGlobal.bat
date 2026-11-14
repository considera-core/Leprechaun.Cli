:: FnEtcDispatchGlobal <Command...>

@ECHO OFF
SETLOCAL EnableExtensions

:: [Function(FnEtcDispatchGlobal)]
:: [Param(Command: string)]
:: [Level(Global)]

:CONSTRUCTOR
    SET "Input_Command=%~1"
    IF NOT DEFINED Input_Command SET "Input_Error=Missing required argument <Command>" & GOTO DESTRUCTOR

:FUNCTION
    CALL FnEtcLogDebug %~n0 "Dispatching command: !Input_Command!"
    CALL FnEtcLogError %~n0 "Unimplemented!"
    GOTO DESTRUCTOR

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "!Input_Error!"
    SET "Input_Error="
    EXIT /B %ERRORLEVEL%