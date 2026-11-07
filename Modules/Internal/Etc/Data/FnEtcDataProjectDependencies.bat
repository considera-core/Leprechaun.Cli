:: FnEtcDataProjectDependencies <OrgId> <SuiteId> <ProjectId>
:: -- Reads Projects.Dependencies.csv (ProjectIdentifier,DependencyIdentifier,CheckFirst).
:: -- Output:
:: --   Output_Data_ProjectDependencies             (ProjectIdentifier[]) space separated dependency identifiers, in file order
:: --   Output_Data_ProjectDependenciesCount        (Integer) count of dependencies
:: --   Output_Data_ProjectDependenciesCheckFirst   (ProjectIdentifier[]) the subset flagged CheckFirst=true

@ECHO OFF

:: INPUT
SET "Input_OrgId=%~1"
SET "Input_SuiteId=%~2"
SET "Input_ProjectId=%~3"

IF NOT DEFINED Input_OrgId CALL FnEtcLogError %~n0 "Missing required argument ^<OrgId^>" & EXIT /B 1
IF NOT DEFINED Input_SuiteId CALL FnEtcLogError %~n0 "Missing required argument ^<SuiteId^>" & EXIT /B 1
IF NOT DEFINED Input_ProjectId CALL FnEtcLogError %~n0 "Missing required argument ^<ProjectId^>" & EXIT /B 1

:: RESOLVE
CALL FnEtcCacheGet "OrgIdentifier[%Input_OrgId%]"
SET "Output_Resolved_OrgIdentifier=%Output_Cache_OrgIdentifier%"
IF NOT DEFINED Output_Resolved_OrgIdentifier CALL FnEtcResolveOrganization "%Input_OrgId%"

CALL FnEtcCacheGet "SuiteIdentifier[%Input_OrgId%][%Input_SuiteId%]"
SET "Output_Resolved_SuiteIdentifier=%Output_Cache_SuiteIdentifier%"
IF NOT DEFINED Output_Resolved_SuiteIdentifier CALL FnEtcResolveSuite "%Input_OrgId%" "%Input_SuiteId%"

:: MAPPING(A: ProjectId, B: DependencyId, C: CheckFirst)
SET "Output_Data_ProjectDependencies="
SET "Output_Data_ProjectDependenciesCount=0"
SET "Output_Data_ProjectDependenciesCheckFirst="
SET "Local_DataFile=%~dp0..\..\..\..\Data\Organizations\%Output_Resolved_OrgIdentifier%\%Output_Resolved_SuiteIdentifier%\Projects.Dependencies.csv"

:: No file means no dependencies, which is valid.
IF NOT EXIST "%Local_DataFile%" EXIT /B 0

FOR /F "usebackq skip=1 tokens=1-3 delims=, eol=#" %%A IN ("%Local_DataFile%") DO (
    IF /I "%%A"=="%Input_ProjectId%" (
        IF DEFINED Output_Data_ProjectDependencies CALL SET "Output_Data_ProjectDependencies=%%Output_Data_ProjectDependencies%% %%B"
        IF NOT DEFINED Output_Data_ProjectDependencies SET "Output_Data_ProjectDependencies=%%B"
        SET /A Output_Data_ProjectDependenciesCount+=1
        IF /I "%%C"=="true" (
            IF DEFINED Output_Data_ProjectDependenciesCheckFirst CALL SET "Output_Data_ProjectDependenciesCheckFirst=%%Output_Data_ProjectDependenciesCheckFirst%% %%B"
            IF NOT DEFINED Output_Data_ProjectDependenciesCheckFirst SET "Output_Data_ProjectDependenciesCheckFirst=%%B"
        )
    )
)

EXIT /B 0
