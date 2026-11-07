[OutputType([bool])]
param
(
    [Parameter(Mandatory)][string]$LinkPath,
    [Parameter(Mandatory)][string]$TargetPath,
    [switch] $DryRun
)

Write-Host "Leprechaun-MakeSym: Making symbolic link at source $LinkPath pointing to target $TargetPath"
Write-Host "Leprechaun-MakeSym: Removing existing link at source to make way for new clean link"
$removed = & "$PSScriptRoot\Leprechaun-RemoveSym.ps1" -LinkPath $LinkPath -DryRun:$DryRun
if (-not $removed)
{
    Write-Host "Leprechaun-MakeSym: FAILED!"
    return $false
}

Write-Host "Leprechaun-MakeSym: Creating symbolic link at source"
if ($DryRun)
{
    Write-Host "Leprechaun-MakeSym: [DRY] Would create symbolic link at $LinkPath pointing to $TargetPath"
}
else
{
    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath -Force | Out-Null
}

Write-Host "Leprechaun-MakeSym: Verifying symbolic link at source"
if ($DryRun -or (Test-Path -Path $LinkPath -PathType Container))
{
    Write-Host "Leprechaun-MakeSym: Symbolic link verified at source"
}
else
{
    Write-Host "Leprechaun-MakeSym: FAILED!"
    return $false
}

return $true