<#
.SYNOPSIS
    FnNugetResolve : find the PackageReference in a .csproj matching a fuzzy
    search term, then look up the latest version on the NuGet feed that ends
    with "-<suffix>" (branch or home tag).

.OUTPUTS
    Plain "KEY=VALUE" lines on stdout, one per line, meant to be parsed by
    the calling .bat via FOR /F "tokens=1,* delims==".

    STATUS=OK|UPTODATE|NOTFOUND|NOMATCH|AMBIGUOUS|ERROR
    PACKAGE_ID=<resolved package id, when known>
    SUFFIX=<sanitized suffix actually searched for>
    CURRENT_VERSION=<version currently in the csproj, when known>
    LATEST_VERSION=<highest matching version found on the feed, when STATUS=OK/UPTODATE>
    MESSAGE=<human readable detail, mainly for non-OK/UPTODATE statuses>
#>
param(
    [Parameter(Mandatory = $true)][string]$CsprojPath,
    [Parameter(Mandatory = $true)][string]$Search,
    [Parameter(Mandatory = $true)][string]$RawSuffix,
    [string]$Source = 'https://tylertech.jfrog.io/artifactory/api/nuget/v3/nuget/index.json',
    [string]$Username = $env:ARTIFACTORY_USERNAME,
    [string]$Password = $env:ARTIFACTORY_PASSWORD
)

$ErrorActionPreference = 'Stop'

function Write-Result {
    param([hashtable]$Fields)
    foreach ($key in @('STATUS', 'PACKAGE_ID', 'SUFFIX', 'CURRENT_VERSION', 'LATEST_VERSION', 'MESSAGE')) {
        if ($Fields.ContainsKey($key)) {
            $value = ($Fields[$key] -replace "`r?`n", ' ')
            Write-Output "$key=$value"
        }
    }
}

function Get-SanitizedSuffix {
    param([string]$Raw)
    $s = $Raw.Trim().ToLowerInvariant()
    $s = [regex]::Replace($s, '[^a-z0-9\-\.]', '-')
    $s = [regex]::Replace($s, '-{2,}', '-')
    $s = $s.Trim('-')
    return $s
}

$Suffix = Get-SanitizedSuffix -Raw $RawSuffix
if (-not $Suffix) {
    Write-Result @{ STATUS = 'ERROR'; MESSAGE = "Could not derive a usable suffix from '$RawSuffix'" }
    exit 1
}

if (-not (Test-Path -LiteralPath $CsprojPath)) {
    Write-Result @{ STATUS = 'ERROR'; MESSAGE = "csproj not found: $CsprojPath" }
    exit 1
}

try {
    [xml]$csprojXml = Get-Content -Raw -LiteralPath $CsprojPath
} catch {
    Write-Result @{ STATUS = 'ERROR'; MESSAGE = "Failed to parse csproj as XML: $($_.Exception.Message)" }
    exit 1
}

$allRefs = @($csprojXml.Project.ItemGroup.PackageReference | Where-Object { $_ -and $_.Include })
$needle = $Search.ToLowerInvariant()
$matches = @($allRefs | Where-Object { $_.Include.ToLowerInvariant().Contains($needle) })

if ($matches.Count -eq 0) {
    Write-Result @{ STATUS = 'NOMATCH'; SUFFIX = $Suffix; MESSAGE = "No PackageReference found matching '$Search' in $CsprojPath" }
    exit 1
}

if ($matches.Count -gt 1) {
    $ids = ($matches | ForEach-Object { $_.Include }) -join ', '
    Write-Result @{ STATUS = 'AMBIGUOUS'; SUFFIX = $Suffix; MESSAGE = "Multiple PackageReferences match '$Search': $ids. Be more specific." }
    exit 1
}

$packageId = $matches[0].Include
$currentVersion = $matches[0].Version
$idLower = $packageId.ToLowerInvariant()

function Get-AuthHeader {
    param([string]$User, [string]$Pass)
    if (-not $User -or -not $Pass) { return $null }
    $pair = "$User`:$Pass"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
    $b64 = [System.Convert]::ToBase64String($bytes)
    return @{ Authorization = "Basic $b64" }
}

$headers = Get-AuthHeader -User $Username -Pass $Password

try {
    $serviceIndex = Invoke-RestMethod -Uri $Source -Headers $headers -Method Get
} catch {
    Write-Result @{ STATUS = 'ERROR'; PACKAGE_ID = $packageId; SUFFIX = $Suffix; CURRENT_VERSION = $currentVersion; MESSAGE = "Failed to reach NuGet feed '$Source': $($_.Exception.Message)" }
    exit 1
}

$regResource = $serviceIndex.resources | Where-Object { $_.'@type' -like 'RegistrationsBaseUrl*' -and $_.'@type' -notlike '*rc*' } | Select-Object -First 1
if (-not $regResource) {
    $regResource = $serviceIndex.resources | Where-Object { $_.'@type' -like 'RegistrationsBaseUrl*' } | Select-Object -First 1
}
if (-not $regResource) {
    Write-Result @{ STATUS = 'ERROR'; PACKAGE_ID = $packageId; SUFFIX = $Suffix; CURRENT_VERSION = $currentVersion; MESSAGE = "Could not find a RegistrationsBaseUrl resource on feed '$Source'" }
    exit 1
}

$regBase = $regResource.'@id'
if (-not $regBase.EndsWith('/')) { $regBase += '/' }
$regIndexUrl = "$regBase$idLower/index.json"

try {
    $regIndex = Invoke-RestMethod -Uri $regIndexUrl -Headers $headers -Method Get
} catch {
    Write-Result @{ STATUS = 'ERROR'; PACKAGE_ID = $packageId; SUFFIX = $Suffix; CURRENT_VERSION = $currentVersion; MESSAGE = "Failed to look up '$packageId' on the feed: $($_.Exception.Message)" }
    exit 1
}

$pages = @($regIndex.items)
if ($pages.Count -eq 0) {
    Write-Result @{ STATUS = 'NOTFOUND'; PACKAGE_ID = $packageId; SUFFIX = $Suffix; CURRENT_VERSION = $currentVersion; MESSAGE = "No versions of '$packageId' found on the feed" }
    exit 1
}

$matchSuffix = "-$Suffix"
$latestVersion = $null

for ($p = $pages.Count - 1; $p -ge 0 -and -not $latestVersion; $p--) {
    $page = $pages[$p]

    $items = $null
    if ($page.PSObject.Properties['items']) {
        $items = @($page.items)
    } else {
        try {
            $fetchedPage = Invoke-RestMethod -Uri $page.'@id' -Headers $headers -Method Get
            $items = @($fetchedPage.items)
        } catch {
            Write-Result @{ STATUS = 'ERROR'; PACKAGE_ID = $packageId; SUFFIX = $Suffix; CURRENT_VERSION = $currentVersion; MESSAGE = "Failed to fetch registration page for '$packageId': $($_.Exception.Message)" }
            exit 1
        }
    }

    for ($i = $items.Count - 1; $i -ge 0; $i--) {
        $entry = $items[$i].catalogEntry
        if (-not $entry) { continue }
        if ($entry.PSObject.Properties['listed'] -and $entry.listed -eq $false) { continue }
        if ($entry.version.ToLowerInvariant().EndsWith($matchSuffix)) {
            $latestVersion = $entry.version
            break
        }
    }
}

if (-not $latestVersion) {
    Write-Result @{ STATUS = 'NOTFOUND'; PACKAGE_ID = $packageId; SUFFIX = $Suffix; CURRENT_VERSION = $currentVersion; MESSAGE = "No version of '$packageId' found on the feed with suffix '-$Suffix'" }
    exit 1
}

if ($latestVersion -ieq $currentVersion) {
    Write-Result @{ STATUS = 'UPTODATE'; PACKAGE_ID = $packageId; SUFFIX = $Suffix; CURRENT_VERSION = $currentVersion; LATEST_VERSION = $latestVersion }
    exit 1
}

Write-Result @{ STATUS = 'OK'; PACKAGE_ID = $packageId; SUFFIX = $Suffix; CURRENT_VERSION = $currentVersion; LATEST_VERSION = $latestVersion }
exit 0
