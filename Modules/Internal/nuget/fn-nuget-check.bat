:: ===========================================================================
:: fn-nuget-check <tenant> <project> <sdk-search> [branch|home]
:: Checks whether a PackageReference in <project>'s csproj (fuzzy-matched by
:: <sdk-search>) has a newer version available on the NuGet feed tagged with
:: the current git branch (default) or the project's home branch (master/main).
::
:: Does NOT modify anything. Sets (does not SETLOCAL, so these bleed up to
:: the caller, e.g. fn-nuget-bump):
::   NUGET_CHECK_STATUS            OK | UPTODATE | NOTFOUND | NOMATCH | AMBIGUOUS | ERROR
::   NUGET_CHECK_PACKAGE_ID
::   NUGET_CHECK_SUFFIX
::   NUGET_CHECK_CURRENT_VERSION
::   NUGET_CHECK_LATEST_VERSION
::   NUGET_CHECK_MESSAGE
::   NUGET_CHECK_CSPROJ_PATH
:: Returns ERRORLEVEL 0 only when STATUS=OK (a newer version was found).
:: ===========================================================================
@ECHO OFF

SET "tenant=%~1"
SET "project=%~2"
SET "sdkSearch=%~3"
SET "mode=%~4"

SET "NUGET_CHECK_STATUS="
SET "NUGET_CHECK_PACKAGE_ID="
SET "NUGET_CHECK_SUFFIX="
SET "NUGET_CHECK_CURRENT_VERSION="
SET "NUGET_CHECK_LATEST_VERSION="
SET "NUGET_CHECK_MESSAGE="
SET "NUGET_CHECK_CSPROJ_PATH="

IF NOT DEFINED tenant (
    ECHO leprechaun/fn-nuget-check[E]: Missing tenant
    ECHO leprechaun/fn-nuget-check[E]: Usage: %~nx0 ^<tenant^> ^<project^> ^<sdk-search^> [branch^|home]
    EXIT /B 1
)

IF NOT DEFINED project (
    ECHO leprechaun/fn-nuget-check[E]: Missing project ^(this command does not support looping across all projects^)
    ECHO leprechaun/fn-nuget-check[E]: Usage: %~nx0 ^<tenant^> ^<project^> ^<sdk-search^> [branch^|home]
    EXIT /B 1
)

IF NOT DEFINED sdkSearch (
    ECHO leprechaun/fn-nuget-check[E]: Missing sdk-search term ^(fuzzy-matched against PackageReference Include values, e.g. "vitals-api"^)
    ECHO leprechaun/fn-nuget-check[E]: Usage: %~nx0 ^<tenant^> ^<project^> ^<sdk-search^> [branch^|home]
    EXIT /B 1
)

IF NOT DEFINED mode SET "mode=branch"
IF /I NOT "%mode%"=="branch" IF /I NOT "%mode%"=="home" (
    ECHO leprechaun/fn-nuget-check[E]: Invalid mode "%mode%" ^(expected "branch" or "home"^)
    EXIT /B 1
)

CALL fn-findTenantRoot "%tenant%"
IF ERRORLEVEL 1 (
    ECHO leprechaun/fn-nuget-check[E]: Could not determine repo root path for tenant "%tenant%"
    EXIT /B 1
)

CALL fn-findProjectByAlias "%project%"
IF ERRORLEVEL 1 (
    ECHO leprechaun/fn-nuget-check[E]: Project alias "%project%" not found
    EXIT /B 1
)

SET "REPO_PATH=%SELECTED_TENANT_ROOT%/%FOUND_NAME%"
SET "NUGET_CHECK_CSPROJ_PATH=%REPO_PATH%/%FOUND_NAME%/%FOUND_NAME%.csproj"

IF NOT EXIST "%NUGET_CHECK_CSPROJ_PATH%" (
    ECHO leprechaun/fn-nuget-check[E]: Could not find csproj at "%NUGET_CHECK_CSPROJ_PATH%"
    EXIT /B 1
)

SET "RAW_SUFFIX="
IF /I "%mode%"=="home" (
    SET "RAW_SUFFIX=%FOUND_HOME%"
) ELSE (
    FOR /F "usebackq delims=" %%B IN (`git -C "%REPO_PATH%" branch --show-current 2^>NUL`) DO SET "RAW_SUFFIX=%%B"
    IF NOT DEFINED RAW_SUFFIX (
        ECHO leprechaun/fn-nuget-check[E]: Could not determine current git branch for %tenant%/%project% ^(detached HEAD?^)
        EXIT /B 1
    )
)

ECHO leprechaun/fn-nuget-check[D]: [Tenant=%tenant% Project=%project% Search=%sdkSearch% Mode=%mode% Branch=%RAW_SUFFIX%]

SET "PS1=%~dp0fn-nuget-resolve.ps1"
FOR /F "usebackq tokens=1,* delims==" %%K IN (`powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -CsprojPath "%NUGET_CHECK_CSPROJ_PATH%" -Search "%sdkSearch%" -RawSuffix "%RAW_SUFFIX%" 2^>^&1`) DO (
    SET "NUGET_CHECK_%%K=%%L"
)

IF NOT DEFINED NUGET_CHECK_STATUS (
    ECHO leprechaun/fn-nuget-check[E]: No response from NuGet resolver script
    EXIT /B 1
)

IF /I "%NUGET_CHECK_STATUS%"=="OK" (
    ECHO leprechaun/fn-nuget-check[I]: %NUGET_CHECK_PACKAGE_ID% can be bumped: %NUGET_CHECK_CURRENT_VERSION% -^> %NUGET_CHECK_LATEST_VERSION%
    EXIT /B 0
)

IF /I "%NUGET_CHECK_STATUS%"=="UPTODATE" (
    ECHO leprechaun/fn-nuget-check[I]: %NUGET_CHECK_PACKAGE_ID% is already up to date at %NUGET_CHECK_CURRENT_VERSION% ^(suffix -%NUGET_CHECK_SUFFIX%^)
    EXIT /B 1
)

IF /I "%NUGET_CHECK_STATUS%"=="NOTFOUND" (
    ECHO leprechaun/fn-nuget-check[E]: %NUGET_CHECK_MESSAGE%
    EXIT /B 1
)

ECHO leprechaun/fn-nuget-check[E]: %NUGET_CHECK_MESSAGE%
EXIT /B 1
