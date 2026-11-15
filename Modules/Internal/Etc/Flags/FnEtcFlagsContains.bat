:: FnEtcFlagsContains <Flag>
:: -- Requires Output_FnEtcFlags_Args
:: -- Returns 1 if the flag is present, 0 otherwise
:: -- A token may itself be a quoted group ("--here --fix"), because the dispatchers
:: --   pass the whole flag list as one quoted argument, so each token is unquoted
:: --   and split again before comparing.

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

SET "Input_Flag=%~1"

FOR %%A IN (%Output_FnEtcFlags_Args%) DO (
    IF /I "%%~A"=="%Input_Flag%" EXIT /B 1
)
EXIT /B 0
