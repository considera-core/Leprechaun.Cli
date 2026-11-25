:: ==============================
:: fn-git-mergeHomeToProd <tenant> <project>
:: ==============================
@ECHO OFF
SET "tenant=%~1"
SET "project=%~2"

IF NOT DEFINED project (
    CALL fn-foreach "%tenant%" "fn-git-mergeHomeToProd" "%project%"
    EXIT /B 0
)

ECHO   [LPRE GIT MERGE HOME TO PROD: %tenant%/%project%]
CALL fn-findTenantRoot "%tenant%"
CALL fn-findProjectByAlias "%project%"

ECHO     [INFO] Merging %FOUND_HOME% branch into production-release with no fast forward

SET "REPO_PATH=%SELECTED_TENANT_ROOT%/%FOUND_NAME%"
SET "STASHED=0"

REM Check if there are uncommitted changes
ECHO     [INFO] Checking for uncommitted changes...
git -C "%REPO_PATH%" diff-index --quiet HEAD -- >NUL 2>&1
IF ERRORLEVEL 1 (
    REM There are changes, check if stash exists
    git -C "%REPO_PATH%" stash list | findstr /R "." >NUL 2>&1
    IF ERRORLEVEL 1 (
        REM No stash exists, stash the changes
        ECHO     [INFO] Stashing changes...
        git -C "%REPO_PATH%" stash push -m "Auto-stash from fn-git-mergeHome" >NUL 2>&1
        SET "STASHED=1"
    ) ELSE (
        ECHO     [INFO] Stash exists, carrying changes over...
    )
)

ECHO     [INFO] Merging branch %FOUND_HOME% into production-release with no fast forward...
CALL fn-git-home "%tenant%" "%project%"
CALL fn-git-pull "%tenant%" "%project%"
CALL fn-git-story "%tenant%" "%project%" "production-release"
CALL fn-git-pull "%tenant%" "%project%"
CALL git -C "%REPO_PATH%" "merge" "--no-ff" "%FOUND_HOME%" >NUL
IF ERRORLEVEL 1 (
    ECHO     [ERROR] GIT MERGE HOME FAILED:
    ECHO       git merge failed for %tenant%/%project% at %REPO_PATH%
    ECHO       Make sure the repo exists and the branch `%FOUND_HOME%` exists.
    ECHO       Make sure there are no merge conflicts.
    REM Pop stash if we stashed
    IF "%STASHED%"=="1" (
        ECHO     [INFO] Restoring stashed changes...
        git -C "%REPO_PATH%" stash pop >NUL 2>&1
    )
    EXIT /B 1
)

REM Pop stash if we stashed
IF "%STASHED%"=="1" (
    ECHO     [INFO] Restoring stashed changes...
    git -C "%REPO_PATH%" stash pop >NUL 2>&1
)

EXIT /B 0