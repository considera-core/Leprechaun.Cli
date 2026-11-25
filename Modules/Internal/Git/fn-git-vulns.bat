:: ===============================
:: fn-git-vulns <tenant> <project> [-v|--verbose]
:: Fetch the count of open Dependabot security alerts (GitHub Security tab)
:: for a repo, via the GitHub API (gh CLI).
::
:: Flags (position-agnostic, parsed by fn-etc-flags):
::   -v, --verbose   Echo the leprechaun/* progress lines. Off by default so
::                   only errors and the final summary are printed.
:: ===============================
@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: Parse all args -> FLAG_ARG_1.. positional, FLAG_* flags (position-agnostic).
CALL fn-etc-flags %*

SET "tenant=%FLAG_ARG_1%"
SET "project=%FLAG_ARG_2%"

:: Verbose if either -v or --verbose was passed anywhere on the line.
SET "VERBOSE="
IF DEFINED FLAG_V SET "VERBOSE=1"
IF DEFINED FLAG_VERBOSE SET "VERBOSE=1"

IF NOT DEFINED project (
    :: Forward the verbose flag to each repo in the fan-out.
    SET "VFLAG="
    IF DEFINED VERBOSE SET "VFLAG=--verbose"
    CALL fn-foreach "%tenant%" "fn-git-vulns" "!VFLAG!"
    EXIT /B 0
)

IF DEFINED VERBOSE ECHO leprechaun/fn-git-vulns[D]: [Tenant=%tenant% Project=%project%]
CALL fn-findTenantRoot "%tenant%"
CALL fn-findProjectByAlias "%project%"

REM gh must be installed & authenticated (gh auth login)
IF DEFINED VERBOSE ECHO leprechaun/fn-git-vulns[D]: Checking for gh CLI...
WHERE gh >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO leprechaun/fn-git-vulns[E]: gh CLI not found on PATH. Install GitHub CLI and run `gh auth login`.
    EXIT /B 1
)

REM cd into the repo so gh resolves {owner}/{repo} from the git remote (gh has no -C flag).
IF DEFINED VERBOSE ECHO leprechaun/fn-git-vulns[D]: Changing directory to repo path...
PUSHD "%SELECTED_TENANT_ROOT%/%FOUND_NAME%" || (
    ECHO leprechaun/fn-git-vulns[E]: Could not cd into repo path for %tenant%/%project%.
    ECHO leprechaun/fn-git-vulns[E]: Attempted path: "%SELECTED_TENANT_ROOT%/%FOUND_NAME%"
    EXIT /B 1
)

IF DEFINED VERBOSE ECHO leprechaun/fn-git-vulns[D]: Resolving GitHub repo for %tenant%/%project%...
SET "GH_REPO="

FOR /F "delims=" %%R IN ('
    gh repo view --json nameWithOwner --jq ".nameWithOwner" 2^>NUL
') DO SET "GH_REPO=%%R"

IF NOT DEFINED GH_REPO (
    ECHO leprechaun/fn-git-vulns[E]: Could not resolve GitHub repo for %tenant%/%project%.
    ECHO leprechaun/fn-git-vulns[E]:     Make sure the repo has a github.com remote and you are authenticated ^(gh auth status^).
    POPD
    EXIT /B 1
)

IF DEFINED VERBOSE ECHO leprechaun/fn-git-vulns[D]: Fetching open Dependabot alerts for %GH_REPO% ...

REM Total open alert count (sum across paginated pages)
SET "VULN_TOTAL="
FOR /F "delims=" %%C IN ('gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open&per_page=100" --paginate --jq "length" 2^>NUL') DO (
    IF NOT DEFINED VULN_TOTAL (SET "VULN_TOTAL=%%C") ELSE (SET /A "VULN_TOTAL+=%%C")
)

IF NOT DEFINED VULN_TOTAL (
    ECHO leprechaun/fn-git-vulns[E]: Failed to query Dependabot alerts for %GH_REPO%.
    ECHO leprechaun/fn-git-vulns[E]:     Dependabot alerts may be disabled, or your token lacks the `repo`/`security_events` scope.
    POPD
    EXIT /B 1
)

REM Validate that VULN_TOTAL contains only digits.
ECHO %VULN_TOTAL%| FINDSTR /R /X "[0-9][0-9]*" >NUL 2>&1 >NUL 2>&1
IF ERRORLEVEL 1 (
    SET "VULN_TOTAL=0 #"
) ELSE (
    SET /A "VULN_TOTAL_INT=%VULN_TOTAL%"
)

IF DEFINED VULN_TOTAL_INT (
    SET "VULN_TOTAL=%VULN_TOTAL_INT%"
    IF !VULN_TOTAL_INT! GTR 5  SET "VULN_TOTAL=%VULN_TOTAL_INT% @"
    IF !VULN_TOTAL_INT! GTR 10 SET "VULN_TOTAL=%VULN_TOTAL_INT% @@"
    IF !VULN_TOTAL_INT! GTR 20 SET "VULN_TOTAL=%VULN_TOTAL_INT% @@@"
    IF !VULN_TOTAL_INT! GTR 30 SET "VULN_TOTAL=%VULN_TOTAL_INT% @@@@"
    IF !VULN_TOTAL_INT! GTR 40 SET "VULN_TOTAL=%VULN_TOTAL_INT% @@@@@"
    IF !VULN_TOTAL_INT! EQU 0 SET "VULN_TOTAL="
)

REM Per-severity breakdown (critical/high/medium/low)
SET "V_CRIT=0"
SET "V_HIGH=0"
SET "V_MED=0"
SET "V_LOW=0"
FOR /F "delims=" %%L IN ('gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open&per_page=100" --paginate --jq ".[].security_advisory.severity" 2^>NUL') DO (
    IF /I "%%L"=="critical" SET /A "V_CRIT+=1"
    IF /I "%%L"=="high"     SET /A "V_HIGH+=1"
    IF /I "%%L"=="medium"   SET /A "V_MED+=1"
    IF /I "%%L"=="moderate" SET /A "V_MED+=1"
    IF /I "%%L"=="low"      SET /A "V_LOW+=1"
)

IF DEFINED VULN_TOTAL (
    ECHO leprechaun/fn-git-vulns[I]: Found %VULN_TOTAL% open vulnerabilities ^(critical=%V_CRIT% high=%V_HIGH% medium=%V_MED% low=%V_LOW%^) in %GH_REPO%
)

IF NOT DEFINED VULN_TOTAL (
    ECHO leprechaun/fn-git-vulns[I]: Found no open vulnerabilities in %GH_REPO%
)
POPD
EXIT /B 0
