:: FnEtcResolveFunction <Module> <Action> <Level>

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnEtcResolveFunction)]
:: [Param(Module, string, required)]
:: [Param(Action, string, optional)]
:: [Param(Level, string, optional)]
:: [Return(Output_Resolved_FunctionName)]
:: [Return(Output_Resolved_FunctionModule)]
:: [Return(Output_Resolved_FunctionAction)]
:: [Return(Output_Resolved_FunctionLevel)]
:: [Return(Output_Resolved_FunctionDescription)]
:: [Level(Root)]

:CONSTRUCTOR
    SET "Input_Module=%~1"
    SET "Input_Action=%~2"
    SET "Input_Level=%~3"
    IF NOT DEFINED Input_Module SET "Input_Error=Missing required argument ^<Module^>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_Action SET "Input_Action=NULL"
    IF NOT DEFINED Input_Level SET "Input_Level=Root"

:FUNCTION
    :: Clean
    CALL FnEtcLogDebug %~n0 "Clearing stale environment"
    FOR /F "delims==" %%V IN ('SET Output_Resolved_Function 2^>NUL') DO SET "%%V="
    CALL FnEtcLogDebug %~n0 "Cleared stale environment"

    :: Resolve
    CALL FnEtcLogDebug %~n0 "Resolving data"
    CALL FnEtcDataFunctions
    IF ERRORLEVEL 1 SET "Input_Error=Failed to resolve data" & GOTO DESTRUCTOR
    CALL FnEtcLogDebug %~n0 "Resolved data"

    echo Resolving function for Module=%Input_Module% Action=%Input_Action% Level=%Input_Level%

    :: Lookup
    SET "Local_Index=0"
    SET "Local_FunctionName="
    SET "Local_FunctionModule="
    SET "Local_FunctionAction="
    SET "Local_FunctionLevel="
    SET "Local_FunctionDescription="
    FOR %%M IN (%Output_Data_Functions%) DO (
        IF NOT DEFINED Local_FunctionName (
            ECHO Checking function %%M against Module=%Input_Module% Action=%Input_Action% Level=%Input_Level%
            IF /I "%Input_Module%"=="%%M" (
                IF /I "%Input_Action%"=="!Output_Data_Function%Local_Index%Action!" (
                    IF /I "%Input_Level%"=="!Output_Data_Function%Local_Index%Level!" (
                        CALL SET "Local_FunctionName=!Output_Data_Function%Local_Index%Name!"
                        CALL SET "Local_FunctionModule=!Output_Data_Function%Local_Index%Module!"
                        CALL SET "Local_FunctionAction=!Output_Data_Function%Local_Index%Action!"
                        CALL SET "Local_FunctionLevel=!Output_Data_Function%Local_Index%Level!"
                        CALL SET "Local_FunctionDescription=!Output_Data_Function%Local_Index%Description!"
                    )
                )
            ) ELSE (
                SET /A Local_Index+=1
                CALL FnEtcLogDebug %~n0 "Skipping function %%M"
            )
        )
    )

    :: Finalize
    ENDLOCAL ^
        & SET "Output_Resolved_FunctionName=%Local_FunctionName%" ^
        & SET "Output_Resolved_FunctionModule=%Local_FunctionModule%" ^
        & SET "Output_Resolved_FunctionAction=%Local_FunctionAction%" ^
        & SET "Output_Resolved_FunctionLevel=%Local_FunctionLevel%" ^
        & SET "Output_Resolved_FunctionDescription=%Local_FunctionDescription%" ^
        & SET "Input_Module=%Input_Module%" ^
        & SET "Input_Action=%Input_Action%" ^
        & SET "Input_Level=%Input_Level%"


    IF NOT DEFINED Local_FunctionName SET "Input_Error=Unknown function %Input_Module% %Input_Action% %Input_Level%" & GOTO DESTRUCTOR
    GOTO DESTRUCTOR

:DESTRUCTOR
    IF DEFINED Input_Error CALL FnEtcLogError %~n0 "%Input_Error%"
    SET "Local_Index="
    SET "Local_FunctionName="
    SET "Local_FunctionModule="
    SET "Local_FunctionAction="
    SET "Local_FunctionLevel="
    SET "Local_FunctionDescription="
    SET "Input_Module="
    SET "Input_Action="
    SET "Input_Level="
    SET "Input_Error="
    EXIT /B %ERRORLEVEL%