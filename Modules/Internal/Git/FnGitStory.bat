@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnGitStory)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(StoryId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" "%~4" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_StoryId=%~4"
    SET "Local_Error="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_StoryId SET "Local_Error=Missing required parameter: StoryId" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnGitStory <OrgId> <SuiteId> <ProjectId> <StoryId> [Flags]"
        ECHO "Goes home, pulls, then switches to (or creates) the story branch, carrying uncommitted changes over."
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
        SET "Local_RepoPath=!Output_Resolved_ProjectPath!"
        SET "Local_Stashed="

        CALL FnEtcLogInfo %~n0 "Checking for uncommitted changes"
        git -C "!Local_RepoPath!" diff-index --quiet HEAD -- >NUL 2>&1
        IF ERRORLEVEL 1 (
            git -C "!Local_RepoPath!" stash list | FINDSTR /R "." >NUL 2>&1
            IF ERRORLEVEL 1 (
                CALL FnEtcLogInfo %~n0 "Stashing changes"
                git -C "!Local_RepoPath!" stash push -m "Auto-stash from FnGitStory" >NUL 2>&1
                SET "Local_Stashed=1"
            ) ELSE (
                CALL FnEtcLogInfo %~n0 "Stash exists, carrying changes over"
            )
        )

        CALL FnEtcLogInfo %~n0 "Fetching from remote"
        git -C "!Local_RepoPath!" fetch --all --prune >NUL 2>&1

        REM Home first, in case the current branch shares no ancestor with the story.
        CALL FnGitHome "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" --here
        CALL FnGitPull "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" --here

        CALL FnEtcLogInfo %~n0 "Switching %Input_SuiteId%/%Input_ProjectId% to %Input_StoryId%"
        git -C "!Local_RepoPath!" switch "%Input_StoryId%" >NUL 2>&1
        IF ERRORLEVEL 1 (
            git -C "!Local_RepoPath!" switch -c "%Input_StoryId%" >NUL 2>&1
            IF ERRORLEVEL 1 (
                IF DEFINED Local_Stashed git -C "!Local_RepoPath!" stash pop >NUL 2>&1
                SET "Local_Error=git switch to %Input_StoryId% failed for %Input_SuiteId%/%Input_ProjectId% at !Local_RepoPath!"
                GOTO :DESTRUCTOR
            )
        )

        IF DEFINED Local_Stashed (
            CALL FnEtcLogInfo %~n0 "Restoring stashed changes"
            git -C "!Local_RepoPath!" stash pop >NUL 2>&1
        )
    ) ELSE (
        CALL FnEtcRunInNewTab "FnGitStory %Input_OrgId% %Input_SuiteId% %Input_ProjectId% %Input_StoryId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_StoryId="
    SET "Local_RepoPath="
    SET "Local_Stashed="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
