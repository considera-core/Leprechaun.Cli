@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnNugetCheck)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Search, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Flag(--home, Match the feed version tagged with the home branch instead of the current branch)]
:: [Return(Output_FnNugetCheck_Status)]
:: [Return(Output_FnNugetCheck_PackageId)]
:: [Return(Output_FnNugetCheck_Suffix)]
:: [Return(Output_FnNugetCheck_CurrentVersion)]
:: [Return(Output_FnNugetCheck_LatestVersion)]
:: [Return(Output_FnNugetCheck_Message)]
:: [Return(Output_FnNugetCheck_CsprojPath)]
:: [Level(Project)]

:: Checks, without changing anything, whether the PackageReference fuzzy matched by
:: <Search> has a newer version on the NuGet feed tagged with the current (or home)
:: branch. Output_FnNugetCheck_Status is OK only when a newer version was found;
:: otherwise UPTODATE, NOTFOUND, NOMATCH, AMBIGUOUS or ERROR. The outputs are only
:: set with --here, because a new tab is a separate shell.

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" "%~4" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_Search=%~4"
    SET "Local_Error="
    SET "Local_Nuget_STATUS="
    SET "Local_Nuget_PACKAGE_ID="
    SET "Local_Nuget_SUFFIX="
    SET "Local_Nuget_CURRENT_VERSION="
    SET "Local_Nuget_LATEST_VERSION="
    SET "Local_Nuget_MESSAGE="
    SET "Local_CsprojPath="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_Search SET "Local_Error=Missing required parameter: Search, fuzzy matched against PackageReference Include values" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnNugetCheck <OrgId> <SuiteId> <ProjectId> <Search> [Flags]"
        ECHO "Checks whether the PackageReference matching <Search> has a newer version on the feed for the branch."
        ECHO "Flags:"
        ECHO "  --here      Run in the current directory"
        ECHO "  --home      Match the feed version tagged with the home branch instead of the current branch"
        ECHO "  --help      Show help information"
        VER >NUL
        GOTO :DESTRUCTOR
    )
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        CALL FnEtcResolveOrganization "%Input_OrgId%"
        CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
        CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
        CALL FnEtcResolveProjectPath
        IF ERRORLEVEL 1 SET "Local_Error=Failed to resolve project path" & GOTO :DESTRUCTOR

        SET "Local_CsprojPath=!Output_Resolved_ProjectPath!\!Output_Resolved_ProjectIdentifier!\!Output_Resolved_ProjectIdentifier!.csproj"
        IF NOT EXIST "!Local_CsprojPath!" SET "Local_CsprojPath=!Output_Resolved_ProjectPath!\!Output_Resolved_ProjectIdentifier!.csproj"
        IF NOT EXIST "!Local_CsprojPath!" SET "Local_Error=Could not find !Output_Resolved_ProjectIdentifier!.csproj in !Output_Resolved_ProjectPath!" & GOTO :DESTRUCTOR

        SET "Local_Branch="
        CALL FnEtcFlagsContains --home
        IF ERRORLEVEL 1 (
            SET "Local_Branch=!Output_Resolved_ProjectHomeBranch!"
        ) ELSE (
            FOR /F "usebackq delims=" %%B IN (`git -C "!Output_Resolved_ProjectPath!" branch --show-current 2^>NUL`) DO SET "Local_Branch=%%B"
        )
        IF NOT DEFINED Local_Branch SET "Local_Error=Could not determine the branch for %Input_SuiteId%/%Input_ProjectId%, detached HEAD?" & GOTO :DESTRUCTOR

        CALL FnEtcLogInfo %~n0 "Checking %Input_Search% in %Input_SuiteId%/%Input_ProjectId% against branch !Local_Branch!"
        FOR /F "usebackq tokens=1,* delims==" %%K IN (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0FnNugetResolve.ps1" -CsprojPath "!Local_CsprojPath!" -Search "%Input_Search%" -RawSuffix "!Local_Branch!" 2^>^&1`) DO (
            SET "Local_Nuget_%%K=%%L"
        )
        IF NOT DEFINED Local_Nuget_STATUS SET "Local_Error=No response from FnNugetResolve.ps1" & GOTO :DESTRUCTOR

        IF /I "!Local_Nuget_STATUS!"=="OK" (
            CALL FnEtcLogInfo %~n0 "!Local_Nuget_PACKAGE_ID! can be bumped: !Local_Nuget_CURRENT_VERSION! to !Local_Nuget_LATEST_VERSION!"
        ) ELSE IF /I "!Local_Nuget_STATUS!"=="UPTODATE" (
            CALL FnEtcLogInfo %~n0 "!Local_Nuget_PACKAGE_ID! is already up to date at !Local_Nuget_CURRENT_VERSION!, suffix -!Local_Nuget_SUFFIX!"
        ) ELSE (
            SET "Local_Error=!Local_Nuget_MESSAGE!"
            GOTO :DESTRUCTOR
        )
    ) ELSE (
        CALL FnEtcRunInNewTab "FnNugetCheck %Input_OrgId% %Input_SuiteId% %Input_ProjectId% %Input_Search% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_Search="
    SET "Local_Error="
    ENDLOCAL ^
        & SET "Output_FnNugetCheck_Status=%Local_Nuget_STATUS%" ^
        & SET "Output_FnNugetCheck_PackageId=%Local_Nuget_PACKAGE_ID%" ^
        & SET "Output_FnNugetCheck_Suffix=%Local_Nuget_SUFFIX%" ^
        & SET "Output_FnNugetCheck_CurrentVersion=%Local_Nuget_CURRENT_VERSION%" ^
        & SET "Output_FnNugetCheck_LatestVersion=%Local_Nuget_LATEST_VERSION%" ^
        & SET "Output_FnNugetCheck_Message=%Local_Nuget_MESSAGE%" ^
        & SET "Output_FnNugetCheck_CsprojPath=%Local_CsprojPath%"
    EXIT /B %ERRORLEVEL%
