:: FnNgBump <SuiteId> <ProjectId> <Version>
:: | FnNgBump <SuiteId> <Version>
:: -- Bumps the version of the specified project within the suite

@ECHO OFF
SETLOCAL EnableExtensions

SET "SuiteId=%~1"
SET "ProjectId=%~2"
SET "Version=%~3"

IF NOT DEFINED SuiteId (
    ECHO LeprechaunCli:FnNgBump[E] SuiteId is missing.
    EXIT /B 1
)

IF NOT DEFINED ProjectId (
    ECHO LeprechaunCli:FnNgBump[E] ProjectId or Version is missing.
    ECHO ProjectId or Version is required.
    EXIT /B 1
)

IF NOT DEFINED Version (
    CALL fn-findProjectByAlias "%ProjectId%"
    IF NOT ERRORLEVEL 1 (
        ECHO LeprechaunCli:FnNgBump[E] Missing Version
        ECHO    Possible usages:
        ECHO    ^| %~nx0 ^<SuiteId^> ^<ProjectId^> ^<Version^>
        ECHO    ^| %~nx0 ^<SuiteId^> ^<Version^>
        EXIT /B 1
    )

    ECHO LeprechaunCli:FnNgBump[D] Calling ForEach with SuiteId=%SuiteId% ProjectId=%ProjectId% Version=%Version%
    CALL fn-forEachAliasByType "bff" "%SuiteId%" FnNgBump
    EXIT /B 0
)

ECHO LeprechaunCli:FnNgBump[D] Called with SuiteId=%SuiteId% ProjectId=%ProjectId% Version=%Version%
ECHO LeprechaunCli:FnNgBump[I] Bumping Angular versions to latest version of %Version%

CALL fn-findTenantRoot "%SuiteId%"
IF ERRORLEVEL 1 (
    ECHO LeprechaunCli:FnNgBump[E] Failed to find tenant root for SuiteId "%SuiteId%"
    EXIT /B 1
)

CALL fn-findProjectByAlias "%ProjectId%"
IF ERRORLEVEL 1 (
    ECHO LeprechaunCli:FnNgBump[E] Failed to find project by alias "%ProjectId%"
    EXIT /B 1
)

PUSHD "%SELECTED_TENANT_ROOT%/%FOUND_NAME%/%FOUND_NAME%/client" || (
    ECHO leprechaun/FnNgBump[E] Could not cd into repo client path.
    ECHO    Attempted path: "%SELECTED_TENANT_ROOT%/%FOUND_NAME%/%FOUND_NAME%/client"
    EXIT /B 1
)

CALL ng update @angular/cli@%Version% @angular/core@%Version%
IF ERRORLEVEL 1 (
    ECHO LeprechaunCli:FnNgBump[E] Failed to update Angular versions to %Version%
    ECHO    Potential solutions:
    ECHO    ^| Ensure your git branch is clean with no uncommited changes
    ECHO    ^| Run "npm install" to ensure all dependencies are installed
    ECHO    ^| Verify that the Angular CLI is installed globally with "npm install -g @angular/cli"
    ECHO    ^| Ensure that you have the necessary permissions to update global packages
    ECHO    ^| Check your internet connection
    ECHO    ^| Ensure that you have the correct Node.js version installed
    ECHO    ^| Try running the command with elevated permissions (Run as Administrator)
) ELSE (
    ECHO LeprechaunCli:FnNgBump[I] Finished bumping Angular versions to %Version%
)

POPD
EXIT /B %ERRORLEVEL%