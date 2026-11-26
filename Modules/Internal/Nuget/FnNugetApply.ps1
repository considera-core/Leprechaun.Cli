<#
.SYNOPSIS
    FnNugetApply : string-replace a single PackageReference's Version
    attribute in a .csproj, preserving the file's original byte encoding.

.OUTPUTS
    STATUS=APPLIED|ERROR
    MESSAGE=<detail, mainly for ERROR>
#>
param(
    [Parameter(Mandatory = $true)][string]$CsprojPath,
    [Parameter(Mandatory = $true)][string]$PackageId,
    [Parameter(Mandatory = $true)][string]$OldVersion,
    [Parameter(Mandatory = $true)][string]$NewVersion
)

$ErrorActionPreference = 'Stop'

function Write-Result {
    param([string]$Status, [string]$Message)
    Write-Output "STATUS=$Status"
    if ($Message) { Write-Output ("MESSAGE=" + ($Message -replace "`r?`n", ' ')) }
}

if (-not (Test-Path -LiteralPath $CsprojPath)) {
    Write-Result -Status 'ERROR' -Message "csproj not found: $CsprojPath"
    exit 1
}

$bytes = [System.IO.File]::ReadAllBytes($CsprojPath)
$hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
$encoding = New-Object System.Text.UTF8Encoding($hasBom)

$content = $encoding.GetString($bytes)
if ($hasBom) { $content = $content.TrimStart([char]0xFEFF) }

$escId = [regex]::Escape($PackageId)
$escOld = [regex]::Escape($OldVersion)

$patterns = @(
    "(<PackageReference\s+Include=""$escId""\s+Version="")$escOld(""\s*/?>)",
    "(<PackageReference\s+Version="")$escOld(""\s+Include=""$escId""\s*/?>)"
)

$replaced = $false
foreach ($pattern in $patterns) {
    $regex = [regex]$pattern
    if ($regex.IsMatch($content)) {
        $evaluator = {
            param($m)
            $m.Groups[1].Value + $NewVersion + $m.Groups[2].Value
        }
        $content = $regex.Replace($content, $evaluator, 1)
        $replaced = $true
        break
    }
}

if (-not $replaced) {
    Write-Result -Status 'ERROR' -Message "Could not find exact PackageReference tag for '$PackageId' version '$OldVersion' in $CsprojPath (file may have changed since check)"
    exit 1
}

[System.IO.File]::WriteAllText($CsprojPath, $content, $encoding)

Write-Result -Status 'APPLIED'
exit 0
