:: ==========================================
:: fn-git-story <tenant> <project> <story-id>
:: ==========================================
@ECHO OFF
SET "tenant=%~1"
SET "project=%~2"
SET "storyId=%~3"

IF NOT DEFINED project (
    ECHO leprechaun/fn-git-story[E]: Missing project or story identifier
    EXIT /B 1
)

:: TWO SCENARIOS
:: 1. fn-git-story <tenant> <project> <story-id>
:: 2. fn-git-story <tenant> <story-id>
:: fn-foreach <tenant> <function> <...args>
::   => fn-git-story <tenant> <project> <storyId>
IF NOT DEFINED storyId (
    CALL fn-findProjectByAlias "%project%"
    IF NOT ERRORLEVEL 1 (
        ECHO leprechaun/fn-git-story[E]: Missing story identifier, got project "%project%" instead
        EXIT /B 1
    )
    CALL fn-foreach "%tenant%" "fn-git-story" "%project%"
    EXIT /B 0
)

CALL fn-findProjectByAlias "%storyId%"
IF NOT ERRORLEVEL 1 (
    ECHO leprechaun/fn-git-story[E]: Missing story identifier, got project "%storyId%" instead
    EXIT /B 1
)

ECHO leprechaun/fn-git-story[D]: [Tenant=%tenant% Project=%project% Story=%storyId%]
CALL fn-findTenantRoot "%tenant%"
CALL fn-findProjectByAlias "%project%"

SET "REPO_PATH=%SELECTED_TENANT_ROOT%/%FOUND_NAME%"
SET "STASHED=0"

ECHO leprechaun/fn-git-story[I]: Checking for uncommitted schenanigans
REM Check if there are uncommitted changes
git -C "%REPO_PATH%" diff-index --quiet HEAD -- >NUL 2>&1
IF ERRORLEVEL 1 (
    REM There are changes, check if stash exists
    git -C "%REPO_PATH%" stash list | findstr /R "." >NUL 2>&1
    IF ERRORLEVEL 1 (
        REM No stash exists, stash the changes
        ECHO leprechaun/fn-git-story[I]: Stashing changes...
        git -C "%REPO_PATH%" stash push -m "Auto-stash from fn-git-story" >NUL 2>&1
        SET "STASHED=1"
    ) ELSE (
        ECHO leprechaun/fn-git-story[I]: Stash exists, carrying changes over...
    )
)

ECHO leprechaun/fn-git-story[I]: Fetching latest news from remote
REM Fetch latest branches and tags
git -C "%REPO_PATH%" fetch --all --prune >NUL 2>&1

ECHO leprechaun/fn-git-story[I]: Going home first
REM Switch to root branch first in case we are on a different branch with no common ancestor
CALL fn-git-home "%tenant%" "%project%"
CALL fn-git-pull "%tenant%" "%project%"

ECHO leprechaun/fn-git-story[I]: Climbing to the %storyId% branch
REM Try to switch to existing branch, or create new one
git -C "%REPO_PATH%" switch "%storyId%" >NUL 2>&1
IF ERRORLEVEL 1 (
    git -C "%REPO_PATH%" switch -c "%storyId%" >NUL 2>&1
    IF ERRORLEVEL 1 (
        ECHO leprechaun/fn-git-story[E]: GIT SWITCH STORY FAILED:
        ECHO leprechaun/fn-git-story[E]:     git switch failed for %tenant%/%project%/%storyId% at %REPO_PATH%
        REM Pop stash if we stashed
        IF "%STASHED%"=="1" (
            ECHO leprechaun/fn-git-story[I]: Restoring stashed changes...
            git -C "%REPO_PATH%" stash pop >NUL 2>&1
        )
        EXIT /B 1
    )
)

ECHO leprechaun/fn-git-story[I]: Recovering the schenanigans
REM Pop stash if we stashed
IF "%STASHED%"=="1" (
    ECHO leprechaun/fn-git-story[I]: Restoring stashed changes...
    git -C "%REPO_PATH%" stash pop >NUL 2>&1
)

EXIT /B 0