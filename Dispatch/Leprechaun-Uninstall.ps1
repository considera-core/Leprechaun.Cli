[OutputType([void])]
param
(
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin)
{
    Write-Host "Leprechaun-Uninstall: FAILED! Administrator privileges are required (needed to remove symbolic links)."
    Write-Host "Leprechaun-Uninstall: Re-run this script from an elevated PowerShell prompt."
    exit 1
}

$symbolicLinkPath = "C:\.symlinks\Leprechaun.Cli"
$binLinkPath = Join-Path $symbolicLinkPath "Bin"
$userPathBackupPath = Join-Path $symbolicLinkPath ("Backup_User_PATH_PreUninstall_{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

Write-Host "Leprechaun-Uninstall: Uninstalling Leprechaun CLI"

Write-Host "Leprechaun-Uninstall: Backing up PATH"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($DryRun)
{
    Write-Host "Leprechaun-Uninstall: [DRY] Would back up PATH to $userPathBackupPath"
}
elseif (Test-Path $symbolicLinkPath)
{
    Set-Content -Path $userPathBackupPath -Value $currentPath
    Write-Host "Leprechaun-Uninstall: Backed up PATH to $userPathBackupPath"
}
else
{
    Write-Host "Leprechaun-Uninstall: Skipping PATH backup as $symbolicLinkPath does not exist"
}

# PATH first, so a failure removing the link never leaves PATH pointing at nothing silently
& "$PSScriptRoot\Leprechaun-RemoveAndRebuildPath.ps1" -LinkPath $binLinkPath -DryRun:$DryRun

Write-Host "Leprechaun-Uninstall: Removing symbolic links"
if (-not (& "$PSScriptRoot\Leprechaun-RemoveSym.ps1" -LinkPath $binLinkPath -DryRun:$DryRun))
{
    Write-Host "Leprechaun-Uninstall: FAILED! Could not remove symbolic link at $binLinkPath"
    exit 1
}

if ($DryRun)
{
    Write-Host "Leprechaun-Uninstall: [DRY] Skipping environment refresh and verification"
    return
}

Write-Host "Leprechaun-Uninstall: Refreshing environment"
$env:PATH = @(
    [Environment]::GetEnvironmentVariable("Path", "Machine"),
    [Environment]::GetEnvironmentVariable("Path", "User")
) -join ";"

Write-Host "Leprechaun-Uninstall: Verifying removal (the test scripts are expected to NOT be found)"
$failed = $false
foreach ($command in @("Leprechaun-Verify-Bat", "Leprechaun-Verify-Ps1"))
{
    if (Get-Command $command -ErrorAction SilentlyContinue)
    {
        Write-Host "Leprechaun-Uninstall: FAILED! $command is still resolvable on PATH"
        $failed = $true
    }
    else
    {
        Write-Host "Leprechaun-Uninstall: OK - $command is no longer available (expected)"
    }
}
if ($failed)
{
    Write-Host "Leprechaun-Uninstall: Verification failed. Another PATH entry (e.g. Machine PATH or this session) may still expose the scripts"
    exit 1
}

Write-Host "Leprechaun-Uninstall: Uninstall complete. Restart other terminals to pick up the PATH change"
Write-Host "Leprechaun-Uninstall: PATH backups remain in $symbolicLinkPath"
