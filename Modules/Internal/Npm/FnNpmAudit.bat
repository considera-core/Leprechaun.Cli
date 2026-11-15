:: FnNpmAudit

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnNpmAudit)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--fix, Safe automatic fix)]
:: [Flag(--here, Run in the current directory)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p %~1 %~2 %~3 -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Local_Error="
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required argument <OrgId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required argument <SuiteId>" & GOTO DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required argument <ProjectId>" & GOTO DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --here
    IF ERRORLEVEL 1 (
        CALL FnEtcResolveOrganization "%Input_OrgId%"
        CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"
        CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
        CALL FnEtcResolveProjectPath
        IF ERRORLEVEL 1 SET "Local_Error=Failed to resolve project path" & GOTO DESTRUCTOR
        CALL FnEtcFlagsContains --fix
        IF ERRORLEVEL 1 (
            PUSHD "!Output_Resolved_ProjectPath!"
            CALL npm run root-audit-fix || CALL npm audit fix
            POPD
        ) ELSE (
            PUSHD "!Output_Resolved_ProjectPath!"
            CALL npm run root-audit || CALL npm audit
            POPD
        )
    ) ELSE (
        CALL FnEtcRunInNewTab "FnNpmAudit %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
        rem CALL FnEtcFlagsContains --fix
        rem     CALL FnEtcRunInNewTab "FnNpmAudit %Input_OrgId% %Input_SuiteId% %Input_ProjectId% --here --fix"
        rem IF ERRORLEVEL 1 (
        rem     CALL FnEtcRunInNewTab "FnNpmAudit %Input_OrgId% %Input_SuiteId% %Input_ProjectId% --here --fix"
        rem ) ELSE (
        rem     CALL FnEtcRunInNewTab "FnNpmAudit %Input_OrgId% %Input_SuiteId% %Input_ProjectId% --here"
        rem )
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_ProjectPath="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%