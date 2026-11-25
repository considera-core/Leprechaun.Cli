:: ==============================
:: fn-npm-coverage <tenant> <project>
:: ==============================
@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

SET "DrivePath=%~dp0"
SET "RootDrive=%DrivePath:~0,2%"
SET "tenant=%~1"
SET "project=%~2"

IF NOT DEFINED tenant (
    ECHO leprechaun/fn-npm-coverage[E]: Missing tenant
    ECHO leprechaun/fn-npm-coverage[E]: Usage: %~nx0 ^<tenant^> ^<project^>
    EXIT /B 1
)

IF NOT DEFINED project (
    ECHO leprechaun/fn-npm-coverage[D]: [Tenant=%tenant% Project=*]
    CALL fn-forEachAliasByType "bff" "%tenant%" fn-npm-coverage
    EXIT /B 0
)

IF NOT EXIST "%RootDrive%/.tmp/coverage" (
    MKDIR "%RootDrive%/.tmp/coverage"
    IF ERRORLEVEL 1 (
        ECHO leprechaun/fn-npm-coverage[E]: Could not create output directory
        EXIT /B 1
    )
    ECHO leprechaun/fn-npm-coverage[D]: Created output directory "%RootDrive%/.tmp/coverage"
)
CALL fn-findTenantRoot "%tenant%"
IF ERRORLEVEL 1 (
    ECHO leprechaun/fn-npm-coverage[E]: Could not determine repo root path
    EXIT /B 1
)

CALL fn-findProjectByAlias "%project%"
IF ERRORLEVEL 1 (
    ECHO leprechaun/fn-npm-coverage[E]: Project alias "%project%" not found
    EXIT /B 1
)

PUSHD "%SELECTED_TENANT_ROOT%/%FOUND_NAME%/%FOUND_NAME%/client" || (
    ECHO leprechaun/fn-npm-coverage[E]: Could not cd into repo client path.
    EXIT /B 1
)

ECHO leprechaun/fn-npm-coverage[D]: [Tenant=%tenant% Project=%project%]
ECHO leprechaun/fn-npm-coverage[I]: Running tests and code-coverage
(
    CALL npm run test:coverage >nul 2>&1
)
IF %ERRORLEVEL% NEQ 0 (
    ECHO leprechaun/fn-npm-coverage[W]: Test run failed
) ELSE (
    ECHO leprechaun/fn-npm-coverage[I]: Test run succeeded
)
IF NOT EXIST ".\coverage\client\coverage-summary.json" (
    ECHO leprechaun/fn-npm-coverage[E]: Coverage summary not found
    EXIT /B 1
)
COPY ".\coverage\client\coverage-summary.json" "%RootDrive%\.tmp\coverage\%tenant%-%project%.json" >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO leprechaun/fn-npm-coverage[W]: Failed to copy coverage summary
) ELSE (
    ECHO leprechaun/fn-npm-coverage[I]: Coverage summary copied successfully
    ECHO leprechaun/fn-npm-coverage[I]: Output saved to "%RootDrive%\.tmp\coverage\%tenant%-%project%.json"
)
POPD
EXIT /B 0
