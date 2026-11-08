@ECHO OFF
SETLOCAL EnableExtensions

SET "Input_Command=%~1"

START wt -w 0 powershell -NoExit -Command "%Input_Command%"
EXIT /B 0