:: ==============================
:: fn-git-fetch <tenant> <project>
:: ==============================
@ECHO OFF
SET "tenant=%~1"
SET "project=%~2"
IF NOT DEFINED project (
    CALL fn-foreach "%tenant%" "fn-git-fetch"
    EXIT /B 0
)

ECHO leprechaun/fn-git-fetch[D]: [Tenant=%tenant% Project=%project%]
CALL fn-findTenantRoot "%tenant%"
CALL fn-findProjectByAlias "%project%"

ECHO leprechaun/fn-git-fetch[I]: Fetching %FOUND_HOME%
CALL git -C "%SELECTED_TENANT_ROOT%/%FOUND_NAME%" fetch
EXIT /B 0
