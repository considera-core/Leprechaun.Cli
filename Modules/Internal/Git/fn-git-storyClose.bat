:: ================================
:: fn-git-storyClose <tenant> <project> <story-ids...>
:: ================================

@ECHO OFF
SET "tenant=%~1"
SET "project=%~2"
CALL fn-etc-args 2 %*
SET "storyIds=%FnEtcArgs%"

IF NOT DEFINED project (
    ECHO [ERROR] Missing project
    ECHO   Usage: fn-git-storyClose ^<tenant^> ^<project^> ^<story-id^>
    EXIT /B 0
)

CALL fn-findProjectByAlias "%project%"
IF ERRORLEVEL 1 (
    ECHO calling fn-foreach %tenant% fn-git-storyClose %project% %storyIds%
    CALL fn-foreach "%tenant%" "fn-git-storyClose" "%project% %storyIds%"
    EXIT /B 0
)

IF NOT DEFINED storyIds (
    ECHO [ERROR] Missing story-ids
    ECHO   Usage: fn-git-storyClose ^<tenant^> ^<project^> ^<story-ids^>
    EXIT /B 0
)

ECHO [LPRE GIT STORY CLOSE: %tenant%/%project%]
CALL fn-findTenantRoot "%tenant%"
CALL fn-git-home "%tenant%" "%project%"

FOR %%I IN (%storyIds%) DO (
    ECHO [INFO] Closing story branch %%I
    CALL git -C "%SELECTED_TENANT_ROOT%/%FOUND_NAME%" "branch" "-d" "%%I"
)

EXIT /B 0
