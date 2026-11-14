:: FnEtcDataFunctions

@ECHO OFF

:: [Function(FnEtcDataFunctions)]
:: [Param()]
:: [Return(Output_Data_Functions)]
:: [Return(Output_Data_FunctionsCount)]
:: [Return(Output_Data_Function<Index>Name)]
:: [Return(Output_Data_Function<Index>Module)]
:: [Return(Output_Data_Function<Index>Action)]
:: [Return(Output_Data_Function<Index>Level)]
:: [Return(Output_Data_Function<Index>Description)]
:: [Level(Root)]

:FUNCTION
    :: Path
    CALL FnEtcLogDebug %~n0 "Getting CSV path"
    CALL FnEtcEnvGetDataPath
    SET "Local_CsvPath=%Output_Env_DataPath%\Functions.csv"
    IF NOT EXIST "%Local_CsvPath%" SET "Input_Error=Functions.csv not found at %Local_CsvPath%" & GOTO DESTRUCTOR
    CALL FnEtcLogDebug %~n0 "Verified CSV path: %Local_CsvPath%"
    
    :: Clean
    CALL FnEtcLogDebug %~n0 "Clearing stale environment"
    FOR /F "delims==" %%V IN ('SET Output_Data_Function 2^>NUL') DO SET "%%V="
    CALL FnEtcLogDebug %~n0 "Cleared stale environment"

    :: Map
    CALL FnEtcLogDebug %~n0 "Mapping CSV data to enviornment"
    SET "Local_Index=0"
    FOR /F "usebackq skip=1 tokens=1,2,3,4,5 delims=, eol=#" %%a IN ("%Local_CsvPath%") DO (
        CALL SET "Output_Data_Functions=%%Output_Data_Functions%% %%a"
        CALL SET "Output_Data_Function%%Local_Index%%Name=%%a"
        CALL SET "Output_Data_Function%%Local_Index%%Module=%%b"
        CALL SET "Output_Data_Function%%Local_Index%%Action=%%c"
        CALL SET "Output_Data_Function%%Local_Index%%Level=%%d"
        CALL SET "Output_Data_Function%%Local_Index%%Description=%%e"
        SET /A Local_Index+=1
    )
    CALL FnEtcLogDebug %~n0 "Mapped %Local_Index% entries"

    :: Finalize
    CALL FnEtcLogDebug %~n0 "Trimming leading separator and setting count"
    IF DEFINED Output_Data_Functions SET "Output_Data_Functions=%Output_Data_Functions:~1%"
    SET "Output_Data_FunctionsCount=%Local_Index%"
    GOTO DESTRUCTOR

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "%Input_Error%"
    CALL FnEtcLogDebug %~n0 "Finished"
    EXIT /B %ERRORLEVEL%
