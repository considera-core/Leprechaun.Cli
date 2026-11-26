@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnNpxExec)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Command, list, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_Command="
    SET "Local_Error="
    FOR %%A IN (!Output_FnEtcFlags_Args!) DO (
        IF NOT "%%~A"=="" IF /I NOT "%%~A"=="--here" IF /I NOT "%%~A"=="--help" SET "Input_Command=!Input_Command! %%A"
    )
    IF DEFINED Input_Command SET "Input_Command=!Input_Command:~1!"
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_Command SET "Local_Error=Missing required parameter: Command" & GOTO :DESTRUCTOR
    SET Local_TabArgs=!Output_FnEtcFlags_Args:"='!

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnNpxExec <OrgId> <SuiteId> <ProjectId> <Command...> [Flags]"
        ECHO "Runs 'npx <Command...>' in the project. Projects without a package.json are skipped."
        ECHO "Flags:"
        ECHO "  --here      Run in the current directory"
        ECHO "  --help      Show help information"
        VER >NUL
        GOTO :DESTRUCTOR
    )
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        CALL FnEtcResolveOrganization "%Input_OrgId%"
        CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
        CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
        CALL FnEtcResolveProjectPath
        IF ERRORLEVEL 1 SET "Local_Error=Failed to resolve project path" & GOTO :DESTRUCTOR
        IF NOT EXIST "!Output_Resolved_ProjectPath!\package.json" (
            CALL FnEtcLogInfo %~n0 "No package.json in %Input_SuiteId%/%Input_ProjectId%, skipping"
            GOTO :DESTRUCTOR
        )
        CALL FnEtcLogInfo %~n0 "Running npx !Input_Command! in %Input_SuiteId%/%Input_ProjectId%"
        PUSHD "!Output_Resolved_ProjectPath!"
        CALL npx !Input_Command!
        POPD
    ) ELSE (
        CALL FnEtcRunInNewTab "FnNpxExec %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Local_TabArgs! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_Command="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
