:: FnEtcForEachProjectDependency <OrgId> <SuiteId> <ProjectId> <FunctionName> <Arg[]>
:: leprechaun function for ProjectDependency <OrgId> <SuiteId> <ProjectId> <FunctionName> <Arg[]>
:: -- Invokes FunctionName once per direct dependency of the project, in the
:: -- order they appear in Projects.Dependencies.csv:
:: --   FunctionName OrgId SuiteId DependencyId ARGS...
:: --
:: -- A project with no dependencies is a valid empty collection. Every
:: -- dependency is attempted even if an earlier one fails, and the return code
:: -- is 1 if any of them failed.

@ECHO OFF
SETLOCAL EnableExtensions
GOTO Constructor

:Main
    CALL FnEtcResolveProjectDependencies "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%"
    IF ERRORLEVEL 1 GOTO Failure

    IF NOT DEFINED Output_Resolved_ProjectDependencies (
        CALL FnEtcLogInfo %~n0 "No dependencies for project %Input_ProjectId%, skipping"
        GOTO Destructor
    )

    FOR %%D IN (%Output_Resolved_ProjectDependencies%) DO (
        CALL %Input_FunctionName% "%Input_OrgId%" "%Input_SuiteId%" "%%D" %Input_Tail%
        IF ERRORLEVEL 1 SET "Input_ReturnCode=1"
    )

    GOTO Destructor

:Constructor
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_FunctionName=%~4"
    SET "Input_Tail="
    SET "Input_Error="
    SET "Input_ReturnCode=0"

    SHIFT
    SHIFT
    SHIFT
    SHIFT
    GOTO Collect

:Collect
    IF [%1]==[] GOTO Collected
    SET "Input_Tail=%Input_Tail% %1"
    SHIFT
    GOTO Collect

:Collected
    IF DEFINED Input_Tail SET "Input_Tail=%Input_Tail:~1%"
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
    IF NOT DEFINED Input_FunctionName (
        SET "Input_Error=Missing required argument <FunctionName>"
        GOTO Failure
    )
    GOTO Main

:Failure
    SET "Input_ReturnCode=1"
    GOTO Destructor

:Destructor
    IF DEFINED Input_Error CALL FnEtcLogError FnEtcForEachProjectDependency "%Input_Error%"
    EXIT /B %Input_ReturnCode%
