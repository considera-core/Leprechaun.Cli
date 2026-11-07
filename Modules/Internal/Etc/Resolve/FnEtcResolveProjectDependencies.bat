:: FnEtcResolveProjectDependencies <OrgId> <SuiteId> <ProjectId>
:: -- Resolves the direct dependencies of a project. Every dependency must be a
:: -- known project in the suite, otherwise the whole resolve fails.
:: -- Output:
:: --   Output_Resolved_ProjectDependencies             (ProjectIdentifier[]) space separated dependency identifiers
:: --   Output_Resolved_ProjectDependenciesCount        (Integer) count of dependencies
:: --   Output_Resolved_ProjectDependenciesCheckFirst   (ProjectIdentifier[]) the subset flagged CheckFirst=true

@ECHO OFF
SETLOCAL EnableExtensions

:: INPUT
SET "Input_OrgId=%~1"
SET "Input_SuiteId=%~2"
SET "Input_ProjectId=%~3"

IF NOT DEFINED Input_OrgId CALL FnEtcLogError %~n0 "Missing required argument ^<OrgId^>" & EXIT /B 1
IF NOT DEFINED Input_SuiteId CALL FnEtcLogError %~n0 "Missing required argument ^<SuiteId^>" & EXIT /B 1
IF NOT DEFINED Input_ProjectId CALL FnEtcLogError %~n0 "Missing required argument ^<ProjectId^>" & EXIT /B 1

:: RESOLVE
CALL FnEtcDataProjectDependencies "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
IF ERRORLEVEL 1 EXIT /B 1

:: VALIDATE
IF DEFINED Output_Data_ProjectDependencies (
    FOR %%D IN (%Output_Data_ProjectDependencies%) DO (
        CALL FnEtcResolveProject "%Input_OrgId%" "%Input_SuiteId%" "%%D"
        IF ERRORLEVEL 1 (
            CALL FnEtcLogError %~n0 "Project %Input_ProjectId% depends on unknown project %%D"
            EXIT /B 1
        )
    )
)

CALL FnEtcLogDebug %~n0 "Resolved dependencies of %Input_ProjectId%: %Output_Data_ProjectDependencies%"

ENDLOCAL ^
    & SET "Output_Resolved_ProjectDependencies=%Output_Data_ProjectDependencies%" ^
    & SET "Output_Resolved_ProjectDependenciesCount=%Output_Data_ProjectDependenciesCount%" ^
    & SET "Output_Resolved_ProjectDependenciesCheckFirst=%Output_Data_ProjectDependenciesCheckFirst%"

EXIT /B 0
