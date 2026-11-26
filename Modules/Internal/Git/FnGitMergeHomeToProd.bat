@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnGitMergeHomeToProd)]
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
    SET "Local_ProdBranch=production-release"
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnGitMergeHomeToProd <OrgId> <SuiteId> <ProjectId> [Flags]"
        ECHO "Merges the home branch into production-release with no fast forward."
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
        IF NOT DEFINED Output_Resolved_ProjectHomeBranch SET "Local_Error=No home branch configured for %Input_SuiteId%/%Input_ProjectId%" & GOTO :DESTRUCTOR
        SET "Local_RepoPath=!Output_Resolved_ProjectPath!"
        SET "Local_HomeBranch=!Output_Resolved_ProjectHomeBranch!"
        SET "Local_Stashed="

        CALL FnEtcLogInfo %~n0 "Checking for uncommitted changes"
        git -C "!Local_RepoPath!" diff-index --quiet HEAD -- >NUL 2>&1
        IF ERRORLEVEL 1 (
            git -C "!Local_RepoPath!" stash list | FINDSTR /R "." >NUL 2>&1
            IF ERRORLEVEL 1 (
                CALL FnEtcLogInfo %~n0 "Stashing changes"
                git -C "!Local_RepoPath!" stash push -m "Auto-stash from FnGitMergeHomeToProd" >NUL 2>&1
                SET "Local_Stashed=1"
            ) ELSE (
                CALL FnEtcLogInfo %~n0 "Stash exists, carrying changes over"
            )
        )

        REM FnGitStory goes home and pulls before it switches, so home is fresh too.
        CALL FnEtcLogInfo %~n0 "Merging !Local_HomeBranch! into !Local_ProdBranch! with no fast forward"
        CALL FnGitStory "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" "!Local_ProdBranch!" --here
        CALL FnGitPull "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" --here

        REM The helpers log their own failures but exit 0, so confirm where we landed.
        SET "Local_Branch="
        FOR /F "usebackq delims=" %%B IN (`git -C "!Local_RepoPath!" branch --show-current`) DO SET "Local_Branch=%%B"
        IF /I NOT "!Local_Branch!"=="!Local_ProdBranch!" (
            IF DEFINED Local_Stashed git -C "!Local_RepoPath!" stash pop >NUL 2>&1
            SET "Local_Error=Expected to be on !Local_ProdBranch! but on !Local_Branch!, not merging"
            GOTO :DESTRUCTOR
        )

        git -C "!Local_RepoPath!" merge --no-ff "!Local_HomeBranch!" >NUL
        IF ERRORLEVEL 1 (
            IF DEFINED Local_Stashed git -C "!Local_RepoPath!" stash pop >NUL 2>&1
            SET "Local_Error=git merge of !Local_HomeBranch! into !Local_ProdBranch! failed for %Input_SuiteId%/%Input_ProjectId%. Check for merge conflicts"
            GOTO :DESTRUCTOR
        )

        IF DEFINED Local_Stashed (
            CALL FnEtcLogInfo %~n0 "Restoring stashed changes"
            git -C "!Local_RepoPath!" stash pop >NUL 2>&1
        )
    ) ELSE (
        CALL FnEtcRunInNewTab "FnGitMergeHomeToProd %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Local_RepoPath="
    SET "Local_HomeBranch="
    SET "Local_ProdBranch="
    SET "Local_Branch="
    SET "Local_Stashed="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
