[OutputType([void])]
param
(
    [Parameter(Mandatory = $true)] [string] $LinkPath,
    [switch] $DryRun
)

Write-Host "Leprechaun-AddAndRebuildPath: Safely adding $LinkPath to user PATH"
$resolvedLink = Resolve-Path $LinkPath -ErrorAction SilentlyContinue
# In a dry run the link may not exist yet, so fall back to the given path
$normalizedLink = $(if ($resolvedLink) { $resolvedLink.Path } else { $LinkPath }).TrimEnd('\')

Write-Host "Leprechaun-AddAndRebuildPath: Normalized link path is $normalizedLink"
$pathEntries = [string[]]@(([Environment]::GetEnvironmentVariable("Path", "User") + "") -split ';' |
    Where-Object { $_ -and $_.Trim() } |
    ForEach-Object { $_.TrimEnd('\') })
$pathSet = [System.Collections.Generic.HashSet[string]]::new(
    $pathEntries,
    [StringComparer]::OrdinalIgnoreCase
)
$containsLink = $pathSet.Contains($normalizedLink)
if (-not $containsLink) {
    $pathSet.Add($normalizedLink) | Out-Null
    Write-Host "Leprechaun-AddAndRebuildPath: Added $normalizedLink to pending user PATH"
} else {
    Write-Host "Leprechaun-AddAndRebuildPath: Skipping $normalizedLink as it is already in user PATH"
    return
}

$cleanPath = ($pathSet | Sort-Object) -join ';'
if ($DryRun) {
    Write-Host "Leprechaun-AddAndRebuildPath: [DRY] Would rebuild user PATH to $cleanPath"
} else {
    [Environment]::SetEnvironmentVariable("Path", $cleanPath, "User")
    Write-Host "Leprechaun-AddAndRebuildPath: Rebuilt user PATH to $cleanPath"
}