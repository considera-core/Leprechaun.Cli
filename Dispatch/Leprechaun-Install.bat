@ECHO OFF
wt -w 0 --title "Leprechaun CLI Installer" -d "%~dp0" powershell -Verb runAs -NoExit -Command ".\Leprechaun-Install.ps1"
IF ERRORLEVEL 1 (
    ECHO [ERROR] Installation failed.
    ECHO   Windows terminal ^(wt^) alias is required.
    ECHO   You may need to manually set the PATH environment variable to something like: C:\Users\<user>\AppData\Local\Microsoft\WindowsApps
    ECHO   You also may need to run this installer from an elevated prompt.
    ECHO   Alternatively, you can run Leprechaun-Install.ps1 directly from an elevated PowerShell prompt.
    EXIT /B 1
)