:: FnEtcFlagsContains <Flag>
:: -- Requires Output_FnEtcFlags_Args
:: -- Returns 1 if the flag is present, 0 otherwise

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

SET "Input_Flag=%~1"

FOR %%A IN (%Output_FnEtcFlags_Args%) DO (
    IF "%%A"=="%Input_Flag%" EXIT /B 1
)
EXIT /B 0