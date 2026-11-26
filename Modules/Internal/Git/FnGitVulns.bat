@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnGitVulns)]
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
        ECHO "Usage: FnGitVulns <OrgId> <SuiteId> <ProjectId> [Flags]"
        ECHO "Counts the open Dependabot security alerts of the project's GitHub repo. Needs the gh CLI, authenticated."
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

        REM Total open alert count, summed across the paginated pages.
        IF DEFINED Local_Verbose CALL FnEtcLogInfo %~n0 "Fetching open Dependabot alerts for !Local_Repo!"
        SET "Local_Total="
        FOR /F "delims=" %%C IN ('gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open&per_page=100" --paginate --jq "length" 2^>NUL') DO (
            IF NOT DEFINED Local_Total (SET /A "Local_Total=%%C") ELSE (SET /A "Local_Total+=%%C")
        )
        IF NOT DEFINED Local_Total SET "Local_Error=Failed to query Dependabot alerts for !Local_Repo!. Alerts may be disabled, or the token lacks the repo/security_events scope" & POPD & GOTO :DESTRUCTOR

        REM Per severity breakdown.
        SET "Local_Critical=0"
        SET "Local_High=0"
        SET "Local_Medium=0"
        SET "Local_Low=0"
        FOR /F "delims=" %%L IN ('gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open&per_page=100" --paginate --jq ".[].security_advisory.severity" 2^>NUL') DO (
            IF /I "%%L"=="critical" SET /A "Local_Critical+=1"
            IF /I "%%L"=="high"     SET /A "Local_High+=1"
            IF /I "%%L"=="medium"   SET /A "Local_Medium+=1"
            IF /I "%%L"=="moderate" SET /A "Local_Medium+=1"
            IF /I "%%L"=="low"      SET /A "Local_Low+=1"
        )

        SET "Local_Marker="
        IF !Local_Total! GTR 5  SET "Local_Marker= @"
        IF !Local_Total! GTR 10 SET "Local_Marker= @@"
        IF !Local_Total! GTR 20 SET "Local_Marker= @@@"
        IF !Local_Total! GTR 30 SET "Local_Marker= @@@@"
        IF !Local_Total! GTR 40 SET "Local_Marker= @@@@@"

        IF !Local_Total! EQU 0 (
            CALL FnEtcLogInfo %~n0 "Found no open vulnerabilities in !Local_Repo!"
        ) ELSE (
            CALL FnEtcLogInfo %~n0 "Found !Local_Total!!Local_Marker! open vulnerabilities (critical=!Local_Critical! high=!Local_High! medium=!Local_Medium! low=!Local_Low!) in !Local_Repo!"
        )
        POPD
    ) ELSE (
        CALL FnEtcRunInNewTab "FnGitVulns %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Local_Verbose="
    SET "Local_Repo="
    SET "Local_Total="
    SET "Local_Critical="
    SET "Local_High="
    SET "Local_Medium="
    SET "Local_Low="
    SET "Local_Marker="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
