:: ==================================
:: fn-git-branches <tenant> <project>
:: ==================================
@ECHO OFF
SET "tenant=%~1"
SET "project=%~2"
IF NOT DEFINED project (
    CALL fn-foreach "%tenant%" "fn-git-branches"
    EXIT /B 0
)

ECHO [LPRE GIT BRANCHES: %tenant%/%project%]
CALL fn-findTenantRoot "%tenant%"
CALL fn-findProjectByAlias "%project%"
CALL git -C "%SELECTED_TENANT_ROOT%/%FOUND_NAME%" "recent-branches"
IF ERRORLEVEL 1 (
    ECHO   [ERROR] Error calling git alias "recent-branches"
    ECHO     Failed to get recent branches for %FOUND_LABEL% ^(%FOUND_NAME%^).
    ECHO     `recent-branches` command needs to be added to your git config.
    ECHO     Refer to the main README.md for instructions.
    EXIT /B 1
)
EXIT /B 0