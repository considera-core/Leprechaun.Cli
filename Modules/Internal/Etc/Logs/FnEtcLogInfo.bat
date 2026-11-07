:: FnEtcLogInfo <Function> <Message>
:: -- Input:
:: --   <Function> The name of the function generating the log message.
:: --   <Message> The informational message to be logged.
:: -- Output:
:: --   void stdout
:: --
:: -- NOTE: The message is captured with delayed expansion off, then echoed
:: --       through it, so <, >, & | and ! in a message print literally.

@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion

CALL FnEtcConfigGet Logs__Info
IF ERRORLEVEL 1 EXIT /B 1
IF NOT "%Output_Config_Value%"=="true" EXIT /B 0

SET "Input_Name=%~1"
SET "Input_Message=%~2"

IF NOT DEFINED Input_Name ECHO "LeprechaunCLI:%~n0[F]: Missing required argument Function" & EXIT /B 1
IF NOT DEFINED Input_Message ECHO "LeprechaunCLI:%~n0[F]: Missing required argument Message" & EXIT /B 1

CALL FnEtcConfigGet "Logs__Info__%Input_Name%"
IF "%Output_Config_Value%"=="false" EXIT /B 0

SETLOCAL EnableDelayedExpansion
ECHO LeprechaunCLI:!Input_Name![I]: !Input_Message!
EXIT /B 0
