@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnGitCountDependabot)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Flag(--verbose, Log each step, not only errors and the summary)]
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
        ECHO "Usage: FnGitCountDependabot <OrgId> <SuiteId> <ProjectId> [Flags]"
        ECHO "Counts the open Dependabot PRs of the project's GitHub repo. Needs the gh CLI, authenticated."
        ECHO "Flags:"
        ECHO "  --here      Run in the current directory"
        ECHO "  --verbose   Log each step, not only errors and the summary"
        ECHO "  --help      Show help information"
        VER >NUL
        GOTO :DESTRUCTOR
    )
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        SET "Local_Verbose="
        CALL FnEtcFlagsContains --verbose
        IF ERRORLEVEL 1 SET "Local_Verbose=1"
        CALL FnEtcResolveOrganization "%Input_OrgId%"
        CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
        CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
        CALL FnEtcResolveProjectPath
        IF ERRORLEVEL 1 SET "Local_Error=Failed to resolve project path" & GOTO :DESTRUCTOR

        WHERE gh >NUL 2>&1
        IF ERRORLEVEL 1 SET "Local_Error=gh CLI not found on PATH. Install GitHub CLI and run gh auth login" & GOTO :DESTRUCTOR

        REM gh has no -C flag, so it resolves owner/repo from the git remote of the current directory.
        PUSHD "!Output_Resolved_ProjectPath!"
        IF DEFINED Local_Verbose CALL FnEtcLogInfo %~n0 "Resolving GitHub repo for %Input_SuiteId%/%Input_ProjectId%"
        SET "Local_Repo="
        FOR /F "delims=" %%R IN ('gh repo view --json nameWithOwner --jq ".nameWithOwner" 2^>NUL') DO SET "Local_Repo=%%R"
        IF NOT DEFINED Local_Repo SET "Local_Error=Could not resolve GitHub repo for %Input_SuiteId%/%Input_ProjectId%. Check the github.com remote and gh auth status" & POPD & GOTO :DESTRUCTOR

        IF DEFINED Local_Verbose CALL FnEtcLogInfo %~n0 "Counting open Dependabot PRs for !Local_Repo!"
        SET "Local_Count=0"
        FOR /F "delims=" %%P IN ('gh pr list --author "app/dependabot" --state open --json number --jq ".[].number" 2^>NUL') DO SET /A "Local_Count+=1"
        CALL FnEtcLogInfo %~n0 "!Local_Count! Dependabot PRs open for !Local_Repo!"
        POPD
    ) ELSE (
        CALL FnEtcRunInNewTab "FnGitCountDependabot %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Local_Verbose="
    SET "Local_Repo="
    SET "Local_Count="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
