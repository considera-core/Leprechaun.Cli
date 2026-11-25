:: ==============================
:: fn-git-pull <tenant> <project>
:: ==============================
@ECHO OFF
SET "tenant=%~1"
SET "project=%~2"
IF NOT DEFINED project (
    CALL fn-foreach "%tenant%" "fn-git-pull"
    EXIT /B 0
)

ECHO leprechaun/fn-git-pull[D]: [Tenant=%tenant% Project=%project%]
CALL fn-findTenantRoot "%tenant%"
CALL fn-findProjectByAlias "%project%"

ECHO leprechaun/fn-git-pull[I]: Pulling from %FOUND_HOME% branch
CALL git -C "%SELECTED_TENANT_ROOT%/%FOUND_NAME%" pull
EXIT /B 0
