@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnIdeRiderDebug)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Local_Error="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnIdeRiderDebug <OrgId> <SuiteId> <ProjectId> [Flags]"
        ECHO "Finds the running dotnet.exe process of the project and attaches the Rider debugger to it."
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
        WHERE rider64.exe >NUL 2>&1
        IF ERRORLEVEL 1 SET "Local_Error=rider64.exe not found on PATH. Add Rider's bin directory to PATH and refresh your terminal" & GOTO :DESTRUCTOR

        REM WMIC is gone from current Windows builds, so the process is found through CIM.
        REM The project's directory name shows up in the command line of its dotnet.exe process.
        CALL FnEtcLogInfo %~n0 "Searching for the running dotnet.exe process of %Input_SuiteId%/%Input_ProjectId%"
        SET "Local_Pid="
        FOR /F "usebackq delims=" %%P IN (`powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'dotnet.exe' -and $_.CommandLine -like '*!Output_Resolved_ProjectRootPath!*' } | Select-Object -First 1 -ExpandProperty ProcessId"`) DO SET "Local_Pid=%%P"
        IF NOT DEFINED Local_Pid SET "Local_Error=No running dotnet.exe process found for %Input_SuiteId%/%Input_ProjectId%. Start the app before attaching the debugger" & GOTO :DESTRUCTOR

        CALL FnEtcLogInfo %~n0 "Attaching Rider debugger to PID !Local_Pid!"
        START "" rider64.exe attach-to-process !Local_Pid! "!Output_Resolved_ProjectPath!"
        IF ERRORLEVEL 1 SET "Local_Error=Failed to attach the Rider debugger to PID !Local_Pid!. Check the process is still running and you have debugging permissions" & GOTO :DESTRUCTOR
    ) ELSE (
        CALL FnEtcRunInNewTab "FnIdeRiderDebug %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Local_Pid="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
