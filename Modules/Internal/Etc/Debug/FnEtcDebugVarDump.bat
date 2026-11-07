:: FnEtcDebugVarDump
:: Dumps the values of all relevant environment variables for debugging purposes.

@ECHO OFF
SETLOCAL EnableExtensions

ECHO DUMPING INPUTS...
FOR /F "tokens=1,2 delims==" %%A IN ('SET Input_') DO (
    ECHO [Debug] %%A=%%B
)
ECHO.

ECHO DUMPING OUTPUTS...
FOR /F "tokens=1,2 delims==" %%A IN ('SET Output_') DO (
    ECHO [Debug] %%A=%%B
)
ECHO.

ECHO DUMPING LOCAL...
FOR /F "tokens=1,2 delims==" %%A IN ('SET Local_') DO (
    ECHO [Debug] %%A=%%B
)
ECHO.

EXIT /B 0