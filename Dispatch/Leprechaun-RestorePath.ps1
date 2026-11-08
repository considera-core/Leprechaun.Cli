[OutputType([bool])]
param
(
    [string] $BackupPath,
    [switch] $DryRun
)

$backupDirectory = "C:\.symlinks\Leprechaun.Cli"

if (-not $BackupPath)
{
    $latest = Get-ChildItem -Path $backupDirectory -Filter "Backup_User_PATH*.txt" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $latest)
    {
        Write-Host "Leprechaun-RestorePath: FAILED! No backup found in $backupDirectory"
        return $false
    }
    $BackupPath = $latest.FullName
}

Write-Host "Leprechaun-RestorePath: Restoring user PATH from $BackupPath"
if (-not (Test-Path -LiteralPath $BackupPath -PathType Leaf))
{
    Write-Host "Leprechaun-RestorePath: FAILED! Backup file not found: $BackupPath"
    return $false
}

$backedUpPath = (Get-Content -LiteralPath $BackupPath -Raw)
if ($null -ne $backedUpPath) { $backedUpPath = $backedUpPath.Trim() }
if ([string]::IsNullOrWhiteSpace($backedUpPath))
{
    Write-Host "Leprechaun-RestorePath: FAILED! Backup file is empty; refusing to wipe user PATH"
    return $false
}

if ($DryRun)
{
    Write-Host "Leprechaun-RestorePath: [DRY] Would restore user PATH to $backedUpPath"
    return $true
}

# Save the PATH being replaced so the restore itself can be undone
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$preRestorePath = Join-Path (Split-Path $BackupPath -Parent) ("Backup_User_PATH_PreRestore_{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
Set-Content -LiteralPath $preRestorePath -Value $currentPath
Write-Host "Leprechaun-RestorePath: Saved current user PATH to $preRestorePath"

[Environment]::SetEnvironmentVariable("Path", $backedUpPath, "User")
Write-Host "Leprechaun-RestorePath: Restored user PATH. Restart your terminal to pick up the change"
return $true
