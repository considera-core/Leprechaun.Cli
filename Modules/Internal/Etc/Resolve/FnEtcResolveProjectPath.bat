:: FnEtcResolveProjectPath
:: -- Input:
:: --   Output_Resolved_OrgRootPath, Output_Resolved_SuiteRootPath, Output_Resolved_ProjectRootPath
:: -- Output:
:: --   Output_Resolved_ProjectPath      organization\suite\project, normalized, no trailing slashes

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

CALL FnEtcLogDebug %~n0 "Inputting <= Output_Resolved_OrgRootPath: %Output_Resolved_OrgRootPath%"
CALL FnEtcLogDebug %~n0 "Inputting <= Output_Resolved_SuiteRootPath: %Output_Resolved_SuiteRootPath%"
CALL FnEtcLogDebug %~n0 "Inputting <= Output_Resolved_ProjectRootPath: %Output_Resolved_ProjectRootPath%"

SET "Local_OrgPath=%Output_Resolved_OrgRootPath%"
IF NOT DEFINED Local_OrgPath (
    CALL FnEtcLogError %~n0 "Organization root path is required."
    EXIT /B 1
)
SET "Local_SuitePath=%Output_Resolved_SuiteRootPath%"
IF NOT DEFINED Local_SuitePath (
    CALL FnEtcLogError %~n0 "Suite root path is required."
    EXIT /B 1
)
SET "Local_ProjPath=%Output_Resolved_ProjectRootPath%"
IF NOT DEFINED Local_ProjPath (
    CALL FnEtcLogError %~n0 "Project root path is required."
    EXIT /B 1
)

:: Normalize forward slashes to backslashes
SET "Local_OrgPath=!Local_OrgPath:/=\!"
SET "Local_SuitePath=!Local_SuitePath:/=\!"
SET "Local_ProjPath=!Local_ProjPath:/=\!"

:: Remove a trailing backslash only if one exists
IF "!Local_OrgPath:~-1!"=="\" SET "Local_OrgPath=!Local_OrgPath:~0,-1!"
IF "!Local_SuitePath:~-1!"=="\" SET "Local_SuitePath=!Local_SuitePath:~0,-1!"
IF "!Local_ProjPath:~-1!"=="\" SET "Local_ProjPath=!Local_ProjPath:~0,-1!"

ENDLOCAL ^
    & SET "Output_Resolved_ProjectPath=%Local_OrgPath%\%Local_SuitePath%\%Local_ProjPath%"

IF NOT EXIST "%Output_Resolved_ProjectPath%" (
    CALL FnEtcLogError %~n0 "Derived project path does not actually exist!"
    EXIT /B 1
)

CALL FnEtcLogDebug %~n0 "Outputting => Output_Resolved_ProjectPath: %Output_Resolved_ProjectPath%"

EXIT /B 0
