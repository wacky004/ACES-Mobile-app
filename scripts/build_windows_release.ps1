param(
    [string]$Version,
    [string]$OutputRoot = "",
    [string]$InstallerUrl = "",
    [string]$Notes = "CPE Reviewer Windows desktop release with Web Learning.",
    [switch]$SkipSign
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if ([string]::IsNullOrWhiteSpace($Version)) {
    $pubspec = Get-Content -LiteralPath "pubspec.yaml" -Raw
    if ($pubspec -notmatch '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
        throw "Could not read version from pubspec.yaml."
    }
    $Version = $Matches[1]
}

$buildDir = Join-Path $root "build\windows\x64\runner\Release"
$outputDir = Join-Path $root "dist\windows"
$setupName = "CPE-Reviewer-$Version-Windows-x64-Setup.exe"
$setupPath = Join-Path $outputDir $setupName
$appExe = Join-Path $buildDir "cpe_reviewer.exe"

if (Test-Path $outputDir) { Remove-Item -LiteralPath $outputDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw "Windows build failed." }
if (-not (Test-Path -LiteralPath $appExe)) {
    throw "Windows executable not found at $appExe."
}

$iscc = Get-Command iscc.exe -ErrorAction SilentlyContinue
if ($iscc) {
    $isccPath = $iscc.Source
} else {
    $isccCandidates = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
        (Join-Path "${env:ProgramFiles(x86)}" "Inno Setup 6\ISCC.exe"),
        (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
    )
    $isccPath = $isccCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $isccPath -or -not (Test-Path -LiteralPath $isccPath)) {
    throw "Inno Setup ISCC.exe was not found."
}

$pfx = $env:ACES_WINDOWS_PFX_PATH
$pfxPassword = $env:ACES_WINDOWS_PFX_PASSWORD
$signing = -not $SkipSign -and -not [string]::IsNullOrWhiteSpace($pfx)
$certThumbprint = ""

if ($signing) {
    if (-not (Test-Path -LiteralPath $pfx)) {
        throw "ACES_WINDOWS_PFX_PATH does not point to a certificate."
    }
    $signtool = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Filter signtool.exe -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\x64\\' } |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if (-not $signtool) { throw "signtool.exe was not found in the Windows SDK." }

    $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfx, $pfxPassword)
    $certThumbprint = $certificate.Thumbprint
    & $signtool.FullName sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /f $pfx /p $pfxPassword $appExe
    if ($LASTEXITCODE -ne 0) { throw "Signing the application failed." }
} else {
    Write-Warning "Building an unsigned Windows release. Set ACES_WINDOWS_PFX_PATH and ACES_WINDOWS_PFX_PASSWORD to sign."
}

& $isccPath "/DMyAppVersion=$Version" "installer\windows\aces_reviewer.iss"
if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed." }
if (-not (Test-Path -LiteralPath $setupPath)) {
    throw "Setup executable not found at $setupPath."
}

if ($signing) {
    & $signtool.FullName sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /f $pfx /p $pfxPassword $setupPath
    if ($LASTEXITCODE -ne 0) { throw "Signing the installer failed." }
}

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $setupPath).Hash.ToLower()
$size = (Get-Item -LiteralPath $setupPath).Length
if ([string]::IsNullOrWhiteSpace($InstallerUrl)) {
    $InstallerUrl = "https://github.com/wacky004/ACES-Reviewer-Releases/releases/download/v$Version/$setupName"
}

$manifest = [ordered]@{
    version = $Version
    installer_url = $InstallerUrl
    sha256 = $hash
    notes = $Notes
    publisher_thumbprint = $certThumbprint
    mandatory = $false
} | ConvertTo-Json -Depth 3
$manifestPath = Join-Path $outputDir "latest.json"
Set-Content -LiteralPath $manifestPath -Value $manifest -Encoding UTF8

if (-not [string]::IsNullOrWhiteSpace($OutputRoot)) {
    New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
    Copy-Item -LiteralPath $setupPath -Destination $OutputRoot -Force
    Copy-Item -LiteralPath $manifestPath -Destination $OutputRoot -Force
}

"$setupName|$size|$hash"
Write-Host "Windows release written to $outputDir"
