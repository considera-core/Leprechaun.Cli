[OutputType([bool])]
param
(
    [Parameter(Mandatory)][string]$LinkPath,
    [switch] $DryRun
)

Write-Host "Leprechaun-RemoveSym: Removing symbolic link at source $LinkPath"
$existing = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
if ($existing)
{
    if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)
    {
        if ($DryRun)
        {
            Write-Host "Leprechaun-RemoveSym: [DRY] Would remove symbolic link at $LinkPath"
            return $true
        }
        else
        {
            $existing.Delete()
            Write-Host "Leprechaun-RemoveSym: Symbolic link removed at source"
        }
    }
    else
    {
        Write-Host "Leprechaun-RemoveSym: Path exists and is not a symbolic link"
        return $false
    }
}
return $true