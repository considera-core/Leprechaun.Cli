[OutputType([void])]
param
(
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin)
{
    Write-Host "Leprechaun-Install: FAILED! Administrator privileges are required (needed to create symbolic links)."
    Write-Host "Leprechaun-Install: Re-run this script from an elevated PowerShell prompt."
    exit 1
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$symbolicLinkPath = "C:\.symlinks\Leprechaun.Cli"
$userPathBackupPath = Join-Path $symbolicLinkPath ("Backup_User_PATH_{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

Write-Host "Leprechaun-Install: Installing Leprechaun CLI"

Write-Host "Leprechaun-Install: Building Leprechaun CLI firstly"
& "$PSScriptRoot\Leprechaun-Build.ps1" -DryRun:$DryRun
Write-Host "Leprechaun-Install: Build complete"

Write-Host "Leprechaun-Install: Placing symbolic links for Leprechaun CLI in $symbolicLinkPath"
if (-not (Test-Path $symbolicLinkPath))
{
    if ($DryRun)
    {
        Write-Host "Leprechaun-Install: [DRY] Would create directory at $symbolicLinkPath"
    }
    else
    {
        New-Item -ItemType Directory -Path $symbolicLinkPath | Out-Null
        Write-Host "Leprechaun-Install: Created directory at $symbolicLinkPath"
    }
}

Write-Host "Leprechaun-Install: Backing up PATH"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($DryRun)
{
    Write-Host "Leprechaun-Install: [DRY] Would back up PATH to $userPathBackupPath"
}
else
{
    Set-Content -Path $userPathBackupPath -Value $currentPath
    Write-Host "Leprechaun-Install: Backed up PATH to $userPathBackupPath"
}

Write-Host "Leprechaun-Install: Actuating symbolic links"
if (-not (& "$PSScriptRoot\Leprechaun-MakeSym.ps1" -LinkPath (Join-Path $symbolicLinkPath "Bin") -TargetPath (Join-Path $repoRoot "Bin") -DryRun:$DryRun))
{
    Write-Host "Leprechaun-Install: FAILED! Could not create symbolic link (are you running elevated?)"
    exit 1
}
& "$PSScriptRoot\Leprechaun-AddAndRebuildPath.ps1" -LinkPath (Join-Path $symbolicLinkPath "Bin") -DryRun:$DryRun

if ($DryRun)
{
    Write-Host "Leprechaun-Install: [DRY] Skipping environment refresh and verification"
    return
}

Write-Host "Leprechaun-Install: Refreshing environment"
$env:PATH = @(
    [Environment]::GetEnvironmentVariable("Path", "Machine"),
    [Environment]::GetEnvironmentVariable("Path", "User")
) -join ";"

Write-Host "Leprechaun-Install: Installation complete"
Write-Host "Leprechaun-Install: Verifying test scripts"
& Leprechaun-Verify-Bat
& Leprechaun-Verify-Ps1
Write-Host "Leprechaun-Install: Verification complete"
