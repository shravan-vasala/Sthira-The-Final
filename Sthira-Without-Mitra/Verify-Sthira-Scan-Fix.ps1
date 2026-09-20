[CmdletBinding()]
param([string]$ProjectRoot = $PSScriptRoot)

$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath($ProjectRoot)
$pubspec = Join-Path $root 'pubspec.yaml'
if (!(Test-Path -LiteralPath $pubspec -PathType Leaf)) {
    throw 'Run this verifier in the actual Sthira project folder containing pubspec.yaml, after merging the ZIP files.'
}
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Sthira-Scan-Fix.manifest.json') -Raw | ConvertFrom-Json
$failed = @()
foreach ($entry in $manifest.files) {
    $target = [System.IO.Path]::GetFullPath((Join-Path $root $entry.path))
    if (!$target.StartsWith($root.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Invalid manifest path.'
    }
    if (!(Test-Path -LiteralPath $target -PathType Leaf)) {
        $failed += $entry.path
        Write-Host ('[MISSING] ' + $entry.path)
        continue
    }
    $actual = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    if ($actual -ne $entry.sha256) {
        $failed += $entry.path
        Write-Host ('[DIFFERENT] ' + $entry.path)
    } else {
        Write-Host ('[OK] ' + $entry.path)
    }
}
if ($failed.Count -gt 0) {
    throw 'The combined fix does not match this project. Merge the four source/test files from the ZIP into this exact project before rebuilding.'
}
Write-Host ''
Write-Host 'All four files match the verified fix.'
Write-Host 'Next: rebuild and install/update the app on your phone. This checks source files, not the installed APK.'
