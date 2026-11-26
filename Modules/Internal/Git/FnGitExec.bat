@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnGitExec)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Command, list, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Flag(--no-confirm, Do not ask for confirmation before running a command that changes the repo)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_Command="
    SET "Local_Error="
    FOR %%A IN (!Output_FnEtcFlags_Args!) DO (
        IF NOT "%%~A"=="" IF /I NOT "%%~A"=="--here" IF /I NOT "%%~A"=="--help" IF /I NOT "%%~A"=="--no-confirm" SET "Input_Command=!Input_Command! %%A"
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
        ECHO "Usage: FnGitExec <OrgId> <SuiteId> <ProjectId> <Command...> [Flags]"
        ECHO "Flags:"
        ECHO "  --here        Run in the current directory"
        ECHO "  --no-confirm  Do not ask for confirmation before running a command that changes the repo"
        ECHO "  --help        Show help information"
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

        REM Hard block: deleting a protected branch, locally or on the remote.
        REM Substitution is case insensitive, so -d also catches -D.
        SET "Local_Blocked="
        FOR %%B IN (master main production-release !Output_Resolved_ProjectHomeBranch!) DO (
            IF NOT "!Input_Command:branch -d %%B=!"=="!Input_Command!" SET "Local_Blocked=%%B"
            IF NOT "!Input_Command:branch --delete %%B=!"=="!Input_Command!" SET "Local_Blocked=%%B"
            IF NOT "!Input_Command:push=!"=="!Input_Command!" (
                IF NOT "!Input_Command:--delete %%B=!"=="!Input_Command!" SET "Local_Blocked=%%B"
                IF NOT "!Input_Command::%%B=!"=="!Input_Command!" SET "Local_Blocked=%%B"
            )
        )
        IF DEFINED Local_Blocked SET "Local_Error=Refusing to delete protected branch !Local_Blocked!" & GOTO :DESTRUCTOR

        REM Read only commands skip the confirmation.
        SET "Local_ReadOnly="
        SET "Local_Verb="
        FOR /F "tokens=1" %%T IN ("!Input_Command!") DO SET "Local_Verb=%%T"
        FOR %%V IN (status log diff show fetch remote branch switch tag) DO IF /I "!Local_Verb!"=="%%V" SET "Local_ReadOnly=1"
        FOR %%V IN (branch switch tag) DO IF /I "!Local_Verb!"=="%%V" (
            IF NOT "!Input_Command: -d=!"=="!Input_Command!" SET "Local_ReadOnly="
            IF NOT "!Input_Command: --delete=!"=="!Input_Command!" SET "Local_ReadOnly="
        )
        IF /I "!Local_Verb!"=="tag" (
            IF NOT "!Input_Command: -a=!"=="!Input_Command!" SET "Local_ReadOnly="
            IF NOT "!Input_Command: -s=!"=="!Input_Command!" SET "Local_ReadOnly="
        )
        IF NOT DEFINED Local_ReadOnly (
            CALL FnEtcFlagsContains --no-confirm
            IF NOT ERRORLEVEL 1 (
                ECHO "Run 'git !Input_Command!' in %Input_SuiteId%/%Input_ProjectId%? (y/N)"
                SET /P Local_Confirm=
                IF /I NOT "!Local_Confirm!"=="y" SET "Local_Error=Cancelled by user" & GOTO :DESTRUCTOR
            )
        )

        CALL FnEtcLogInfo %~n0 "Running git !Input_Command! in %Input_SuiteId%/%Input_ProjectId%"
        git -C "!Output_Resolved_ProjectPath!" !Input_Command!
    ) ELSE (
        CALL FnEtcRunInNewTab "FnGitExec %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Local_TabArgs! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_Command="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
