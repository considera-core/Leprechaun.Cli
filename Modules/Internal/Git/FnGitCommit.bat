@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnGitCommit)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Message, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--here, Run in the current directory)]
:: [Flag(--push, Push after committing)]
:: [Flag(--state, Check state after committing & pushing)]
:: [Flag(--no-add, Do not automatically stage files)]
:: [Flag(--no-confirm, Do not ask for confirmation before committing or pushing)]
:: [Flag(--help, Show help information)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" "%~4" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_Message=%~4"
    SET "Local_Error="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required argument <OrgId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required argument <SuiteId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required argument <ProjectId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_Message SET "Local_Error=Missing required argument <Message>" & GOTO DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        echo 1
        ECHO "Usage: FnGitCommit <OrgId> <SuiteId> <ProjectId> <Message> [Flags]"
        ECHO "Flags:"
        ECHO "  --here       Run in the current directory"
        ECHO "  --push       Push after committing"
        ECHO "  --state      Check state after committing & pushing"
        ECHO "  --no-add    Do not automatically stage files"
        ECHO "  --no-confirm Do not ask for confirmation before committing or pushing"
        ECHO "  --help      Show help information"
        VER >NUL
        GOTO DESTRUCTOR
    )
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        CALL FnEtcResolveOrganization "%Input_OrgId%"
        CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
        CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
        CALL FnEtcResolveProjectPath
        IF ERRORLEVEL 1 SET "Local_Error=Failed to resolve project path" & GOTO DESTRUCTOR
        PUSHD "!Output_Resolved_ProjectPath!"
        CALL FnEtcFlagsContains --no-add
        IF NOT ERRORLEVEL 1 (
            CALL git add .
        )
        CALL FnEtcFlagsContains --no-confirm
        IF NOT ERRORLEVEL 1 (
            ECHO "Are you sure you want to commit? (y/N)"
            SET /P Local_Confirm=
            IF /I NOT "!Local_Confirm!"=="y" SET "Local_Error=Commit cancelled by user" & POPD & GOTO DESTRUCTOR
        )

        CALL git commit -m "%Input_Message%"
        CALL FnEtcFlagsContains --push
        IF ERRORLEVEL 1 (
            CALL FnEtcFlagsContains --no-confirm
            IF NOT ERRORLEVEL 1 (
                ECHO "Are you sure you want to push? (y/N)"
                SET /P Local_Confirm=
                IF /I NOT "!Local_Confirm!"=="y" SET "Local_Error=Commit cancelled by user" & POPD & GOTO DESTRUCTOR
            )
            CALL git push
        )
        CALL FnEtcFlagsContains --state
        IF ERRORLEVEL 1 (
            CALL FnEtcLogInfo %~n0 "Checking git state after commit and push"
            CALL git status
        )
        POPD
    ) ELSE (
        SET "Local_Message=!Input_Message:'=''!"
        CALL FnEtcRunInNewTab "FnGitCommit %Input_OrgId% %Input_SuiteId% %Input_ProjectId% '!Local_Message!' !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_Message="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%