@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnNugetBump)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Search, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Flag(--home, Match the feed version tagged with the home branch instead of the current branch)]
:: [Flag(--no-confirm, Do not ask for confirmation before bumping)]
:: [Level(Project)]

:: Runs FnNugetCheck and, when a newer version is available, shows the PackageReference
:: diff and asks for confirmation before string replacing the Version in the csproj.

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" "%~4" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_Search=%~4"
    SET "Local_Error="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_Search SET "Local_Error=Missing required parameter: Search, fuzzy matched against PackageReference Include values" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnNugetBump <OrgId> <SuiteId> <ProjectId> <Search> [Flags]"
        ECHO "Bumps the PackageReference matching <Search> to the newest feed version for the branch."
        ECHO "Flags:"
        ECHO "  --here        Run in the current directory"
        ECHO "  --home        Match the feed version tagged with the home branch instead of the current branch"
        ECHO "  --no-confirm  Do not ask for confirmation before bumping"
        ECHO "  --help        Show help information"
        VER >NUL
        GOTO :DESTRUCTOR
    )
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        SET "Local_CheckFlags=--here"
        CALL FnEtcFlagsContains --home
        IF ERRORLEVEL 1 SET "Local_CheckFlags=--here --home"
        CALL FnNugetCheck "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" "%Input_Search%" !Local_CheckFlags!
        IF /I NOT "!Output_FnNugetCheck_Status!"=="OK" (
            CALL FnEtcLogInfo %~n0 "Nothing to bump"
            GOTO :DESTRUCTOR
        )

        ECHO.
        ECHO !Output_FnNugetCheck_CsprojPath!
        ECHO   - ^<PackageReference Include="!Output_FnNugetCheck_PackageId!" Version="!Output_FnNugetCheck_CurrentVersion!" /^>
        ECHO   + ^<PackageReference Include="!Output_FnNugetCheck_PackageId!" Version="!Output_FnNugetCheck_LatestVersion!" /^>
        ECHO.

        CALL FnEtcFlagsContains --no-confirm
        IF NOT ERRORLEVEL 1 (
            SET "Local_Answer="
            SET /P "Local_Answer=Press ENTER to bump, or Q to cancel: "
            IF /I "!Local_Answer!"=="Q" SET "Local_Error=Cancelled by user, not bumping !Output_FnNugetCheck_PackageId!" & GOTO :DESTRUCTOR
        )

        SET "Local_Apply_STATUS="
        SET "Local_Apply_MESSAGE="
        FOR /F "usebackq tokens=1,* delims==" %%K IN (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0FnNugetApply.ps1" -CsprojPath "!Output_FnNugetCheck_CsprojPath!" -PackageId "!Output_FnNugetCheck_PackageId!" -OldVersion "!Output_FnNugetCheck_CurrentVersion!" -NewVersion "!Output_FnNugetCheck_LatestVersion!" 2^>^&1`) DO (
            SET "Local_Apply_%%K=%%L"
        )
        IF /I NOT "!Local_Apply_STATUS!"=="APPLIED" SET "Local_Error=!Local_Apply_MESSAGE!" & GOTO :DESTRUCTOR
        CALL FnEtcLogInfo %~n0 "Bumped !Output_FnNugetCheck_PackageId! to !Output_FnNugetCheck_LatestVersion! in !Output_FnNugetCheck_CsprojPath!"
    ) ELSE (
        CALL FnEtcRunInNewTab "FnNugetBump %Input_OrgId% %Input_SuiteId% %Input_ProjectId% %Input_Search% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_Search="
    SET "Local_CheckFlags="
    SET "Local_Answer="
    SET "Local_Apply_STATUS="
    SET "Local_Apply_MESSAGE="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
