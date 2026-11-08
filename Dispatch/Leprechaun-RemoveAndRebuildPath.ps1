[OutputType([void])]
param
(
    [Parameter(Mandatory = $true)] [string] $LinkPath,
    [switch] $DryRun
)

Write-Host "Leprechaun-RemoveAndRebuildPath: Safely removing $LinkPath from user PATH"
$resolvedLink = Resolve-Path $LinkPath -ErrorAction SilentlyContinue

# Match both the path as given and its resolved form (the link may already be gone)
$targets = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$targets.Add($LinkPath.TrimEnd('\')) | Out-Null
if ($resolvedLink) { $targets.Add($resolvedLink.Path.TrimEnd('\')) | Out-Null }
Write-Host "Leprechaun-RemoveAndRebuildPath: Matching entries: $($targets -join ', ')"

$pathEntries = [string[]]@(([Environment]::GetEnvironmentVariable("Path", "User") + "") -split ';' |
    Where-Object { $_ -and $_.Trim() } |
    ForEach-Object { $_.TrimEnd('\') })

# Preserve the original order, dropping duplicates and the target entries
$seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$kept = [System.Collections.Generic.List[string]]::new()
$removed = $false
foreach ($entry in $pathEntries)
{
    if ($targets.Contains($entry)) { $removed = $true; continue }
    if ($seen.Add($entry)) { $kept.Add($entry) }
}

if (-not $removed)
{
    Write-Host "Leprechaun-RemoveAndRebuildPath: Skipping as $LinkPath is not in user PATH"
    return
}

$cleanPath = $kept -join ';'
if ($DryRun)
{
    Write-Host "Leprechaun-RemoveAndRebuildPath: [DRY] Would rebuild user PATH to $cleanPath"
}
else
{
    [Environment]::SetEnvironmentVariable("Path", $(if ($cleanPath) { $cleanPath } else { $null }), "User")
    Write-Host "Leprechaun-RemoveAndRebuildPath: Rebuilt user PATH to $cleanPath"
}
