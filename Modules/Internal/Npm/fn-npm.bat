:: ==========================================
:: fn-npm <tenant> <project> <npm-command>
:: ==========================================
@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

SET "tenant=%~1"
SET "project=%~2"
SET "command=%~3"

IF NOT DEFINED tenant (
    ECHO leprechaun/fn-npm[E]: Missing tenant
    ECHO leprechaun/fn-npm[E]: Usage: %~nx0 ^<tenant^> ^<project^> ^<npm-command^> [args...]
    EXIT /B 1
)

IF NOT DEFINED project (
    ECHO leprechaun/fn-npm[E]: Missing project or story identifier
    ECHO leprechaun/fn-npm[E]: Usage: %~nx0 ^<tenant^> ^<project^> ^<npm-command^> [args...]
    EXIT /B 1
)

IF NOT DEFINED command (
    CALL fn-findProjectByAlias "%project%"
    IF NOT ERRORLEVEL 1 (
        ECHO leprechaun/fn-npm[E]: Missing npm command, got project "%project%" instead
        ECHO leprechaun/fn-npm[E]: Usage: %~nx0 ^<tenant^> ^<project^> ^<npm-command^> [args...]
        EXIT /B 1
    )
    ECHO leprechaun/fn-npm[D]: [Tenant=%tenant% Project=*]
    CALL fn-forEachAliasByType "bff" "%tenant%" fn-npm
    EXIT /B 0
)

CALL fn-findProjectByAlias "%command%"
IF NOT ERRORLEVEL 1 (
    ECHO leprechaun/fn-npm[E]: Missing npm command, got project "%command%" instead
    ECHO leprechaun/fn-npm[E]: Usage: %~nx0 ^<tenant^> ^<project^> ^<npm-command^> [args...]
    EXIT /B 1
)


:: Build args string from %4..%9
SET "args=%~4 %~5 %~6 %~7 %~8 %~9"
SET "full=%command% %args%"

GOTO :FN
EXIT /B %ERRORLEVEL%

:FN
    ECHO leprechaun/fn-npm[D]: [Tenant=%tenant% Project=%project%]
    ECHO leprechaun/fn-npm[I]: Running npm %full%

    CALL fn-findTenantRoot "%tenant%"
    IF ERRORLEVEL 1 (
        ECHO leprechaun/fn-npm[E]: Could not determine repo root path
        EXIT /B 1
    )

    CALL fn-findProjectByAlias "%project%"
    IF ERRORLEVEL 1 (
        ECHO leprechaun/fn-npm[E]: Project alias "%project%" not found
        EXIT /B 1
    )

    PUSHD "%SELECTED_TENANT_ROOT%/%FOUND_NAME%/%FOUND_NAME%/client" || (
        ECHO leprechaun/fn-npm[E]: Could not cd into repo client path.
        ECHO leprechaun/fn-npm[E]: Attempted path: "%SELECTED_TENANT_ROOT%/%FOUND_NAME%/%FOUND_NAME%/client"
        EXIT /B 1
    )

    npm %full%
    SET "rc=%ERRORLEVEL%"

    POPD
    EXIT /B %rc%
