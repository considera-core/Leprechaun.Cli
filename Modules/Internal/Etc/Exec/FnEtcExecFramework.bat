
SET "Input_FrameworkId=%Output_Resolved_ProjectFrameworkId%"
CALL FnEtcResolveProjectPath


IF /I "%Input_FrameworkId%"=="dotnet" (
    PUSHD "%Output_Resolved_ProjectPath%"
    CALL dotnet watch 
    POPD
    IF ERRORLEVEL 1 GOTO Failure
    EXIT /B 0
)
IF /I "%Input_FrameworkId%"=="ng" (
    PUSHD "%Output_Resolved_ProjectPath%"
    CALL npm run root-run
    POPD
    IF ERRORLEVEL 1 GOTO Failure
    EXIT /B 0
)
IF /I "%Input_FrameworkId%"=="caddy" (
    PUSHD "%Output_Resolved_ProjectPath%"
    CALL caddy run Caddyfile
    POPD
    IF ERRORLEVEL 1 GOTO Failure
    EXIT /B 0
)
IF /I "%Input_FrameworkId%"=="terraform" (
    PUSHD "%Output_Resolved_ProjectPath%"
    CALL terraform apply
    POPD
    IF ERRORLEVEL 1 GOTO Failure
    EXIT /B 0
)
IF /I "%Input_FrameworkId%"=="unity" (
    PUSHD "%Output_Resolved_ProjectPath%"
    CALL Unity.exe -projectPath "%Output_Resolved_ProjectPath%" -executeMethod BuildScript.Build
    POPD
    IF ERRORLEVEL 1 GOTO Failure
    EXIT /B 0
)
SET "Input_Error=Unsupported framework %Input_FrameworkId%"
GOTO Failure

:Failure
    CALL FnEtcLogError FnEtcExecFramework "%Input_Error%"
    EXIT /B 1