@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnNgBump)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Version, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" "%~4" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_Version=%~4"
    SET "Local_Error="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_Version SET "Local_Error=Missing required parameter: Version" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnNgBump <OrgId> <SuiteId> <ProjectId> <Version> [Flags]"
        ECHO "Runs 'ng update @angular/cli@<Version> @angular/core@<Version>'. Projects not on the ng framework are skipped."
        ECHO "Flags:"
        ECHO "  --here      Run in the current directory"
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
        IF /I NOT "!Output_Resolved_ProjectFrameworkId!"=="ng" (
            CALL FnEtcLogInfo %~n0 "%Input_SuiteId%/%Input_ProjectId% is not an Angular project, skipping"
            GOTO :DESTRUCTOR
        )
        CALL FnEtcLogInfo %~n0 "Bumping Angular to %Input_Version% in %Input_SuiteId%/%Input_ProjectId%"
        PUSHD "!Output_Resolved_ProjectPath!"
        CALL npx ng update @angular/cli@%Input_Version% @angular/core@%Input_Version%
        IF ERRORLEVEL 1 (
            CALL FnEtcLogWarning %~n0 "Potential solutions:"
            CALL FnEtcLogWarning %~n0 "| Make sure the git branch is clean, with no uncommitted changes"
            CALL FnEtcLogWarning %~n0 "| Run npm install so all dependencies are installed"
            CALL FnEtcLogWarning %~n0 "| Check the Angular CLI is installed: npm install -g @angular/cli"
            CALL FnEtcLogWarning %~n0 "| Check your internet connection and Node.js version"
            CALL FnEtcLogWarning %~n0 "| Try again from an elevated terminal"
            SET "Local_Error=Failed to update Angular to %Input_Version% in %Input_SuiteId%/%Input_ProjectId%"
            POPD
            GOTO :DESTRUCTOR
        )
        POPD
        CALL FnEtcLogInfo %~n0 "Finished bumping Angular to %Input_Version% in %Input_SuiteId%/%Input_ProjectId%"
    ) ELSE (
        CALL FnEtcRunInNewTab "FnNgBump %Input_OrgId% %Input_SuiteId% %Input_ProjectId% %Input_Version% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_Version="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
