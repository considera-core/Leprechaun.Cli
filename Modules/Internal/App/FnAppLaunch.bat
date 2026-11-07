:: FnAppLaunch <OrgId> <SuiteId> <ProjectId> <Arg[]> <Flag[]>
:: leprechaun function app launch <OrgId> <SuiteId> <ProjectId> <Arg[]>
:: -- Launches an app in a project based on its' type.
:: -- Flags:
:: --   --here:               run in this window instead of spawning a new one
:: --   --deps:               ensure project dependencies are resolved before launching
:: --   -v, --verbose:        verbose
:: --   -d, --dry-run:        report what would run, do not run it

@ECHO OFF
SETLOCAL EnableExtensions
GOTO Constructor

:Main
    :: Dependencies first, each launched through this same function with neither
    :: --here (so each gets its own tab) nor --deps (so this stays one level deep).
    CALL FnEtcFlagsContains --deps
    IF ERRORLEVEL 1 (
        CALL FnEtcForEachProjectDependency "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" FnAppLaunch
        IF ERRORLEVEL 1 GOTO Failure
    )

    :: The new tab is a fresh shell with none of our resolved variables, so it
    :: re-enters FnAppLaunch with --here rather than calling FnEtcExecFramework bare.
    :: (No comments inside the block below: "::" in a parenthesized block is parsed
    :: as a label and fails with "The system cannot find the drive specified.")
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        CALL FnEtcExecFramework
    ) ELSE (
        CALL FnEtcRunInNewTab "FnAppLaunch %Input_OrgId% %Input_SuiteId% %Input_ProjectId% --here"
    )

    IF ERRORLEVEL 1 GOTO Failure
    GOTO Destructor

:Constructor
    CALL FnEtcFlags -p %~1 %~2 %~3 -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_Error="
    SET "Input_ReturnCode=0"
    GOTO Validate

:Validate
    IF NOT DEFINED Input_OrgId (
        SET "Input_Error=Missing required argument <OrgId>"
        GOTO Failure
    )
    IF NOT DEFINED Input_SuiteId (
        SET "Input_Error=Missing required argument <SuiteId>"
        GOTO Failure
    )
    IF NOT DEFINED Input_ProjectId (
        SET "Input_Error=Missing required argument <ProjectId>"
        GOTO Failure
    )
    CALL FnEtcResolveOrganization "%Input_OrgId%"
    IF ERRORLEVEL 1 GOTO Failure
    CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
    IF ERRORLEVEL 1 GOTO Failure
    CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
    IF ERRORLEVEL 1 GOTO Failure
    GOTO Main

:Failure
    SET "Input_ReturnCode=1"
    GOTO Destructor

:Destructor
    IF DEFINED Input_Error CALL FnEtcLogError FnAppLaunch "%Input_Error%"
    EXIT /B %Input_ReturnCode%