$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$modId = 'MouseCursorConsoles'
$modsRoot = Join-Path $env:APPDATA 'Surviving Mars Relaunched\Mods'
$destination = [IO.Path]::GetFullPath((Join-Path $modsRoot $modId))
if ((Split-Path -Parent $destination) -ne [IO.Path]::GetFullPath($modsRoot)) {
    throw "Deployment escaped Mods directory: $destination"
}
$payload = @('metadata.lua', 'items.lua', 'Images/test-not-ready.png') + @(Get-ChildItem (Join-Path $projectRoot 'Code') -File -Filter '*.lua' | ForEach-Object { 'Code/' + $_.Name })
foreach ($relative in $payload) {
    if (!(Test-Path -LiteralPath (Join-Path $projectRoot $relative) -PathType Leaf)) { throw "Missing payload file: $relative" }
    if ($relative.EndsWith('.lua')) {
        & luac -p (Join-Path $projectRoot $relative)
        if ($LASTEXITCODE -ne 0) { throw "Syntax check failed: $relative" }
    }
}
if (Test-Path -LiteralPath $destination) {
    if ((Get-Item -LiteralPath $destination).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Refusing reparse-point deployment destination: $destination"
    }
    $installedMetadata = Join-Path $destination 'metadata.lua'
    if (!(Test-Path -LiteralPath $installedMetadata) -or
        !(Select-String -LiteralPath $installedMetadata -SimpleMatch "'id', `"$modId`"" -Quiet)) {
        throw "Destination ownership is unverified: $destination"
    }
    foreach ($existing in Get-ChildItem -LiteralPath $destination -Recurse -Force) {
        if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Refusing deployment through reparse point: $($existing.FullName)"
        }
        if (!$existing.PSIsContainer) {
            $relative = $existing.FullName.Substring($destination.Length + 1).Replace('\', '/')
            if ($relative -notin $payload) { throw "Unexpected destination file (preserved): $relative" }
        }
    }
}
New-Item -ItemType Directory -Path (Join-Path $destination 'Code') -Force | Out-Null
foreach ($relative in $payload) {
    $source = Join-Path $projectRoot $relative
    $target = Join-Path $destination $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Force
    if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) {
        throw "Deployment hash mismatch: $relative"
    }
}
Write-Output "Verified $($payload.Count) payload files in $destination (no files deleted)."
