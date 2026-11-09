param(
    [string]$Version = "1.6.0",
    [string]$OutputRoot = $env:CPE_RELEASE_DIR
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $desktop = Split-Path $root -Parent
    $OutputRoot = Join-Path $desktop "CPE APP REVIWER"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

flutter build web --release
if ($LASTEXITCODE -ne 0) { throw "Web build failed." }

$webZip = Join-Path $OutputRoot "CPE-Reviewer-Web-$Version.zip"
if (Test-Path $webZip) { Remove-Item -LiteralPath $webZip -Force }
Compress-Archive -Path "build\web\*" -DestinationPath $webZip -CompressionLevel Optimal

$apkOut = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkOut) { Remove-Item -LiteralPath $apkOut -Force }
flutter build apk --release --target-platform android-arm64
if ($LASTEXITCODE -ne 0) { throw "arm64 APK build failed." }
Copy-Item -LiteralPath $apkOut -Destination (Join-Path $OutputRoot "CPE-Reviewer-$Version-AI-arm64.apk") -Force

if (Test-Path $apkOut) { Remove-Item -LiteralPath $apkOut -Force }
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "Universal APK build failed." }
Copy-Item -LiteralPath $apkOut -Destination (Join-Path $OutputRoot "CPE-Reviewer-$Version-AI-universal.apk") -Force

$files = @(
    (Join-Path $OutputRoot "CPE-Reviewer-$Version-AI-arm64.apk"),
    (Join-Path $OutputRoot "CPE-Reviewer-$Version-AI-universal.apk"),
    $webZip
)
$files | ForEach-Object {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_).Hash
    $size = (Get-Item -LiteralPath $_).Length
    "$(Split-Path $_ -Leaf)|$size|$hash"
}
Write-Host "Release artifacts written to $OutputRoot"
