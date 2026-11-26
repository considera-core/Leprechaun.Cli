@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: [Function(FnGitStoryClose)]
:: [Param(OrgId, string, required)]
:: [Param(SuiteId, string, required)]
:: [Param(ProjectId, string, required)]
:: [Param(StoryIds, list, required)]
:: [Param(Flags, list, optional)]
:: [Flag(--help, Show help information)]
:: [Flag(--here, Run in the current directory)]
:: [Level(Project)]

:CONSTRUCTOR
    CALL FnEtcFlags -p "%~1" "%~2" "%~3" -a %*
    SET "Input_OrgId=%~1"
    SET "Input_SuiteId=%~2"
    SET "Input_ProjectId=%~3"
    SET "Input_StoryIds="
    SET "Local_Error="
    FOR %%A IN (!Output_FnEtcFlags_Args!) DO (
        IF NOT "%%~A"=="" IF /I NOT "%%~A"=="--here" IF /I NOT "%%~A"=="--help" SET "Input_StoryIds=!Input_StoryIds! %%~A"
    )
    IF DEFINED Input_StoryIds SET "Input_StoryIds=!Input_StoryIds:~1!"
    IF NOT DEFINED Input_OrgId SET "Local_Error=Missing required parameter: OrgId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_SuiteId SET "Local_Error=Missing required parameter: SuiteId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_ProjectId SET "Local_Error=Missing required parameter: ProjectId" & GOTO :DESTRUCTOR
    IF NOT DEFINED Input_StoryIds SET "Local_Error=Missing required parameter: StoryIds" & GOTO :DESTRUCTOR

:FUNCTION
    CALL FnEtcFlagsContains --help
    IF ERRORLEVEL 1 (
        ECHO "Usage: FnGitStoryClose <OrgId> <SuiteId> <ProjectId> <StoryId...> [Flags]"
        ECHO "Goes home, then deletes each merged story branch. Protected branches are skipped."
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
        SET "Local_RepoPath=!Output_Resolved_ProjectPath!"
        SET "Local_Protected= master main production-release !Output_Resolved_ProjectHomeBranch! "

        CALL FnGitHome "%Input_OrgId%" "%Input_SuiteId%" "%Input_ProjectId%" --here

        FOR %%I IN (!Input_StoryIds!) DO (
            IF NOT "!Local_Protected: %%I =!"=="!Local_Protected!" (
                CALL FnEtcLogWarning %~n0 "Skipping protected branch %%I"
            ) ELSE (
                CALL FnEtcLogInfo %~n0 "Closing story branch %%I in %Input_SuiteId%/%Input_ProjectId%"
                git -C "!Local_RepoPath!" branch -d "%%I"
            )
        )
    ) ELSE (
        CALL FnEtcRunInNewTab "FnGitStoryClose %Input_OrgId% %Input_SuiteId% %Input_ProjectId% !Output_FnEtcFlags_Args! --here"
    )

:DESTRUCTOR
    IF DEFINED Local_Error CALL FnEtcLogError %~n0 "%Local_Error%"
    SET "Input_OrgId="
    SET "Input_SuiteId="
    SET "Input_ProjectId="
    SET "Input_StoryIds="
    SET "Local_RepoPath="
    SET "Local_Protected="
    SET "Local_Error="
    EXIT /B %ERRORLEVEL%
