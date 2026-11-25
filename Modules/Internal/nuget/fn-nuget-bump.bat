:: ===========================================================================
:: fn-nuget-bump <tenant> <project> <sdk-search> [branch|home]
:: Runs fn-nuget-check, and if a newer version is available, shows a diff of
:: the PackageReference change and asks for confirmation (ENTER to bump,
:: Q to cancel) before string-replacing the Version in the project's csproj.
:: ===========================================================================
@ECHO OFF

SET "tenant=%~1"
SET "project=%~2"
SET "sdkSearch=%~3"
SET "mode=%~4"

CALL fn-nuget-check "%tenant%" "%project%" "%sdkSearch%" "%mode%"
IF ERRORLEVEL 1 (
    ECHO leprechaun/fn-nuget-bump[I]: Nothing to bump.
    EXIT /B 1
)

ECHO(
ECHO leprechaun/fn-nuget-bump[DIFF]: %NUGET_CHECK_CSPROJ_PATH%
ECHO   - ^<PackageReference Include="%NUGET_CHECK_PACKAGE_ID%" Version="%NUGET_CHECK_CURRENT_VERSION%" /^>
ECHO   + ^<PackageReference Include="%NUGET_CHECK_PACKAGE_ID%" Version="%NUGET_CHECK_LATEST_VERSION%" /^>
ECHO(

SET "ans="
SET /P "ans=Press ENTER to bump, or Q to cancel: "
IF /I "%ans%"=="Q" (
    ECHO leprechaun/fn-nuget-bump[CANCELLED]: Not bumping %NUGET_CHECK_PACKAGE_ID%
    EXIT /B 1
)

SET "PS1=%~dp0fn-nuget-apply.ps1"
SET "NUGET_APPLY_STATUS="
SET "NUGET_APPLY_MESSAGE="
FOR /F "usebackq tokens=1,* delims==" %%K IN (`powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -CsprojPath "%NUGET_CHECK_CSPROJ_PATH%" -PackageId "%NUGET_CHECK_PACKAGE_ID%" -OldVersion "%NUGET_CHECK_CURRENT_VERSION%" -NewVersion "%NUGET_CHECK_LATEST_VERSION%" 2^>^&1`) DO (
    SET "NUGET_APPLY_%%K=%%L"
)

IF /I "%NUGET_APPLY_STATUS%"=="APPLIED" (
    ECHO leprechaun/fn-nuget-bump[I]: Bumped %NUGET_CHECK_PACKAGE_ID% to %NUGET_CHECK_LATEST_VERSION% in %NUGET_CHECK_CSPROJ_PATH%
    EXIT /B 0
)

ECHO leprechaun/fn-nuget-bump[E]: %NUGET_APPLY_MESSAGE%
EXIT /B 1
