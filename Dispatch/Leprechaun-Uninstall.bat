@ECHO OFF
wt -w 0 --title "Leprechaun CLI Uninstaller" -d "%~dp0" powershell -Verb runAs -NoExit -Command ".\Leprechaun-Uninstall.ps1"
IF ERRORLEVEL 1 (
    ECHO [ERROR] Uninstallation failed.
    ECHO   Windows terminal ^(wt^) alias is required.
    ECHO   You also may need to run this uninstaller from an elevated prompt.
    ECHO   Alternatively, you can run Leprechaun-Uninstall.ps1 directly from an elevated PowerShell prompt.
    EXIT /B 1
)
