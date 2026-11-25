:: ===============================
:: fn-git-countDependabot <tenant> <project> [-v|--verbose]
:: Count the number of open Dependabot PRs for a repo, via the GitHub API
:: (gh CLI). Handy for comparing before/after running fn-git-refreshDependabot.
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
    CALL fn-foreach "%tenant%" "fn-git-countDependabot" "!VFLAG!"
    EXIT /B 0
)

IF DEFINED VERBOSE ECHO leprechaun/fn-git-countDependabot[D]: [Tenant=%tenant% Project=%project%]
CALL fn-findTenantRoot "%tenant%"
CALL fn-findProjectByAlias "%project%"

REM gh must be installed & authenticated (gh auth login)
IF DEFINED VERBOSE ECHO leprechaun/fn-git-countDependabot[D]: Checking for gh CLI...
WHERE gh >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO leprechaun/fn-git-countDependabot[E]: gh CLI not found on PATH. Install GitHub CLI and run `gh auth login`.
    EXIT /B 1
)

REM cd into the repo so gh resolves {owner}/{repo} from the git remote (gh has no -C flag).
IF DEFINED VERBOSE ECHO leprechaun/fn-git-countDependabot[D]: Changing directory to repo path...
PUSHD "%SELECTED_TENANT_ROOT%/%FOUND_NAME%" || (
    ECHO leprechaun/fn-git-countDependabot[E]: Could not cd into repo path for %tenant%/%project%.
    ECHO leprechaun/fn-git-countDependabot[E]: Attempted path: "%SELECTED_TENANT_ROOT%/%FOUND_NAME%"
    EXIT /B 1
)

IF DEFINED VERBOSE ECHO leprechaun/fn-git-countDependabot[D]: Resolving GitHub repo for %tenant%/%project%...
SET "GH_REPO="

FOR /F "delims=" %%R IN ('
    gh repo view --json nameWithOwner --jq ".nameWithOwner" 2^>NUL
') DO SET "GH_REPO=%%R"

IF NOT DEFINED GH_REPO (
    ECHO leprechaun/fn-git-countDependabot[E]: Could not resolve GitHub repo for %tenant%/%project%.
    ECHO leprechaun/fn-git-countDependabot[E]:     Make sure the repo has a github.com remote and you are authenticated ^(gh auth status^).
    POPD
    EXIT /B 1
)

IF DEFINED VERBOSE ECHO leprechaun/fn-git-countDependabot[D]: Counting open Dependabot PRs for %GH_REPO% ...

REM Count open PRs authored by the Dependabot GitHub App.
SET "PR_COUNT=0"
FOR /F "delims=" %%P IN ('gh pr list --author "app/dependabot" --state open --json number --jq ".[].number" 2^>NUL') DO (
    SET /A "PR_COUNT+=1"
)

ECHO leprechaun/fn-git-countDependabot[I]: %PR_COUNT% Dependabot PR(s) for %GH_REPO%

POPD
EXIT /B 0
