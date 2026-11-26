:: FnEtcResolveFunction <Module> <Action>
:: -- Looks up the function for a module and action in Data\Functions.csv.

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnEtcResolveFunction)]
:: [Param(Module, string, required)]
:: [Param(Action, string, required)]
:: [Return(Output_Resolved_FunctionName)]
:: [Return(Output_Resolved_FunctionModule)]
:: [Return(Output_Resolved_FunctionAction)]
:: [Return(Output_Resolved_FunctionLevel)]
:: [Return(Output_Resolved_FunctionDescription)]
:: [Level(Root)]

:CONSTRUCTOR
    SET "Input_Module=%~1"
    SET "Input_Action=%~2"
    SET "Local_Error="
    SET "Local_Name="
    SET "Local_Module="
    SET "Local_Action="
    SET "Local_Level="
    SET "Local_Description="
    IF NOT DEFINED Input_Module SET "Local_Error=Missing required parameter: Module" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_Action SET "Local_Error=Missing required parameter: Action" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcDataFunctions
    IF NOT DEFINED Output_Data_FunctionsCount SET "Local_Error=Failed to read Functions.csv" & GOTO :DESTRUCTOR
    SET /A "Local_Last=Output_Data_FunctionsCount-1"
    FOR /L %%I IN (0,1,!Local_Last!) DO (
        IF NOT DEFINED Local_Name IF /I "!Output_Data_Function%%IModule!"=="%Input_Module%" IF /I "!Output_Data_Function%%IAction!"=="%Input_Action%" (
            SET "Local_Name=!Output_Data_Function%%IName!"
            SET "Local_Module=!Output_Data_Function%%IModule!"
            SET "Local_Action=!Output_Data_Function%%IAction!"
            SET "Local_Level=!Output_Data_Function%%ILevel!"
            SET "Local_Description=!Output_Data_Function%%IDescription!"
        )
    )
    IF NOT DEFINED Local_Name SET "Local_Error=No function for module %Input_Module% and action %Input_Action% in Functions.csv"

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    ENDLOCAL ^
        & SET "Output_Resolved_FunctionName=%Local_Name%" ^
        & SET "Output_Resolved_FunctionModule=%Local_Module%" ^
        & SET "Output_Resolved_FunctionAction=%Local_Action%" ^
        & SET "Output_Resolved_FunctionLevel=%Local_Level%" ^
        & SET "Output_Resolved_FunctionDescription=%Local_Description%"
    IF NOT DEFINED Output_Resolved_FunctionName EXIT /B 1
    EXIT /B 0
