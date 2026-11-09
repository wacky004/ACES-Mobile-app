param(
    [switch]$FixFormat
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if ($FixFormat) {
    dart format lib test
} else {
    dart format --output=none --set-exit-if-changed lib test
    if ($LASTEXITCODE -ne 0) { throw "Dart formatting check failed." }
}

flutter analyze
if ($LASTEXITCODE -ne 0) { throw "Flutter analyze failed." }

flutter test
if ($LASTEXITCODE -ne 0) { throw "Flutter tests failed." }

Write-Host "Verification passed."
