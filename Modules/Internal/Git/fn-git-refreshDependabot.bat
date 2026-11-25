:: ===============================
:: fn-git-refreshDependabot <tenant> <project> [-v|--verbose]
:: Find all open Dependabot PRs for a repo and comment '@dependabot recreate'
:: on each one, via the GitHub API (gh CLI).
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
    CALL fn-foreach "%tenant%" "fn-git-refreshDependabot" "!VFLAG!"
    EXIT /B 0
)

IF DEFINED VERBOSE ECHO leprechaun/fn-git-refreshDependabot[D]: [Tenant=%tenant% Project=%project%]
CALL fn-findTenantRoot "%tenant%"
CALL fn-findProjectByAlias "%project%"

REM gh must be installed & authenticated (gh auth login)
IF DEFINED VERBOSE ECHO leprechaun/fn-git-refreshDependabot[D]: Checking for gh CLI...
WHERE gh >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO leprechaun/fn-git-refreshDependabot[E]: gh CLI not found on PATH. Install GitHub CLI and run `gh auth login`.
    EXIT /B 1
)

REM cd into the repo so gh resolves {owner}/{repo} from the git remote (gh has no -C flag).
IF DEFINED VERBOSE ECHO leprechaun/fn-git-refreshDependabot[D]: Changing directory to repo path...
PUSHD "%SELECTED_TENANT_ROOT%/%FOUND_NAME%" || (
    ECHO leprechaun/fn-git-refreshDependabot[E]: Could not cd into repo path for %tenant%/%project%.
    ECHO leprechaun/fn-git-refreshDependabot[E]: Attempted path: "%SELECTED_TENANT_ROOT%/%FOUND_NAME%"
    EXIT /B 1
)

IF DEFINED VERBOSE ECHO leprechaun/fn-git-refreshDependabot[D]: Resolving GitHub repo for %tenant%/%project%...
SET "GH_REPO="

FOR /F "delims=" %%R IN ('
    gh repo view --json nameWithOwner --jq ".nameWithOwner" 2^>NUL
') DO SET "GH_REPO=%%R"

IF NOT DEFINED GH_REPO (
    ECHO leprechaun/fn-git-refreshDependabot[E]: Could not resolve GitHub repo for %tenant%/%project%.
    ECHO leprechaun/fn-git-refreshDependabot[E]:     Make sure the repo has a github.com remote and you are authenticated ^(gh auth status^).
    POPD
    EXIT /B 1
)

IF DEFINED VERBOSE ECHO leprechaun/fn-git-refreshDependabot[D]: Fetching open Dependabot PRs for %GH_REPO% ...

REM Find open PRs authored by the Dependabot GitHub App and comment on each.
SET "PR_COUNT=0"
FOR /F "delims=" %%P IN ('gh pr list --author "app/dependabot" --state open --json number --jq ".[].number" 2^>NUL') DO (
    SET /A "PR_COUNT+=1"
    IF DEFINED VERBOSE ECHO leprechaun/fn-git-refreshDependabot[D]: Commenting on PR #%%P ...
    gh pr comment %%P --body "@dependabot recreate" >NUL 2>&1
    IF ERRORLEVEL 1 (
        ECHO leprechaun/fn-git-refreshDependabot[E]: Failed to comment on PR #%%P in %GH_REPO%.
    ) ELSE (
        ECHO leprechaun/fn-git-refreshDependabot[I]: Commented "@dependabot recreate" on PR #%%P in %GH_REPO%
    )
)

IF "%PR_COUNT%"=="0" (
    ECHO leprechaun/fn-git-refreshDependabot[I]: No open Dependabot PRs found in %GH_REPO%
)

POPD
EXIT /B 0
