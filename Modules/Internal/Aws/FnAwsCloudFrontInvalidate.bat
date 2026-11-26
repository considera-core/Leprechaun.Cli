@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnAwsCloudFrontInvalidate)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(DistributionId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Flag(--prod, Use the AWS profile from samconfig.prod.toml instead of samconfig.dev.toml)]
:: [Level(Project)]

:: The distribution belongs to the project that owns the stack, so projects without
:: a template.yaml are skipped. That keeps a suite wide call to one invalidation.
:: Every path is invalidated ("/*"); FnEtcFlags expands wildcards in arguments, so
:: paths are not taken as parameters.

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" "%~4" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_DistributionId=%~4"
    SET "Local_Error="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_DistributionId SET "Local_Error=Missing required parameter: DistributionId" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnAwsCloudFrontInvalidate <OrgId> <SuiteId> <ProjectId> <DistributionId> [Flags]"
        ECHO "Invalidates every path of the CloudFront distribution. Projects without a template.yaml are skipped."
        ECHO "Flags:"
        ECHO "  --here      Run in the current directory"
        ECHO "  --prod      Use the AWS profile from samconfig.prod.toml instead of samconfig.dev.toml"
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
        IF NOT EXIST "!Output_Resolved_ProjectPath!\template.yaml" (
            CALL FnEtcLogInfo %~n0 "No template.yaml in %Input_SuiteId%/%Input_ProjectId%, skipping"
            GOTO :DESTRUCTOR
        )
        WHERE aws >NUL 2>&1
        IF ERRORLEVEL 1 SET "Local_Error=aws CLI not found on PATH" & GOTO :DESTRUCTOR

        REM Same profile as the SAM functions use, read from the samconfig file.
        SET "Local_ConfigFile=samconfig.dev.toml"
        CALL FnEtcFlagsContains --prod
        IF ERRORLEVEL 1 SET "Local_ConfigFile=samconfig.prod.toml"
        SET "Local_Profile="
        IF EXIST "!Output_Resolved_ProjectPath!\!Local_ConfigFile!" (
            FOR /F "usebackq tokens=2 delims==" %%V IN (`FINDSTR /B /C:"profile" "!Output_Resolved_ProjectPath!\!Local_ConfigFile!"`) DO FOR %%P IN (%%V) DO SET "Local_Profile=%%~P"
        )
        SET "Local_ProfileArgs="
        IF DEFINED Local_Profile (
            SET "Local_ProfileArgs=--profile !Local_Profile!"
        ) ELSE (
            CALL FnEtcLogWarning %~n0 "No profile in !Local_ConfigFile!, using AWS_PROFILE or the default profile"
        )

        CALL FnEtcLogInfo %~n0 "Invalidating /* on distribution %Input_DistributionId% !Local_ProfileArgs!"
        CALL aws cloudfront create-invalidation --distribution-id "%Input_DistributionId%" --paths "/*" !Local_ProfileArgs!
        IF ERRORLEVEL 1 SET "Local_Error=CloudFront invalidation failed for distribution %Input_DistributionId%" & GOTO :DESTRUCTOR
    ) ELSE (
        CALL FnEtcRunInNewTab "FnAwsCloudFrontInvalidate %Input_OrgId% %Input_SuiteId% %Input_ProjectId% %Input_DistributionId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_DistributionId="
    SET "Local_ConfigFile="
    SET "Local_Profile="
    SET "Local_ProfileArgs="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
