# Functions
function RemoveSymbolicLink {
    param ([string]$linkPath)
    try {
        Remove-Item -Path $linkPath -Force -Recurse -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Failed to remove $linkPath"
    }
    if (Test-Path -Path $linkPath -PathType Container) {
        Write-Host "$linkPath still exists."
    } else {
        Write-Host "$linkPath deleted."
    }
}

Write-Host "Starting Lazy Polyrepo Express Tools uninstallation..."

# Check if Symbolic Links Directory Exists
$LPRE_SYM_PATH = & fn-config get RootSymLinksPath
if (Test-Path -Path "$LPRE_SYM_PATH" -PathType Container) {
    Write-Host "$LPRE_SYM_PATH exists."
    Write-Host "Removing symbolic links for script paths..."
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/Root
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/Config
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/Modules
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/ModulesAi
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/ModulesApp
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/ModulesEtc
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/ModulesGit
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/ModulesIde
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/ModulesNpm
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/Tenants
    RemoveSymbolicLink -linkPath $LPRE_SYM_PATH/TenantsDispatch
} else {
    Write-Host "$LPRE_SYM_PATH does not exist, nothing to uninstall."
}