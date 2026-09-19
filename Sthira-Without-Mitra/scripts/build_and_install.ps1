# build_and_install.ps1
# TruFit Bodamma - Local Build & Install Script

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " TruFit Bodamma Local Builder & Installer" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if ADB sees a device (optional)
$hasAdb = $false
try {
    $devices = adb devices | Select-String -Pattern "\bdevice\b"
    if ($devices -and $devices.Count -gt 0) {
        $hasAdb = $true
        Write-Host "Android device found." -ForegroundColor Green
    } else {
        Write-Host "No Android device connected via ADB. Skipping auto-install." -ForegroundColor Yellow
    }
} catch {
    Write-Host "ADB not found. Skipping auto-install." -ForegroundColor Yellow
}

# Optional: Run flutter analyze and tests
Write-Host "Running flutter analyze..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter analyze found issues. Continuing anyway..." -ForegroundColor Yellow
}

# Build the APK (profile keeps debugging info; switch to --release when keystore is configured)
Write-Host "Building APK..." -ForegroundColor Yellow
& flutter build apk --profile --android-skip-build-dependency-validation
$buildOk = $LASTEXITCODE -eq 0

$apkPath = "build\app\outputs\flutter-apk\app-profile.apk"
$altApk = Join-Path $env:USERPROFILE "temp_trufit_build\app\outputs\flutter-apk\app-profile.apk"
$desktopApk = Join-Path $env:USERPROFILE "Desktop\TruFit-Bodamma-profile.apk"

# Custom Gradle buildDirectory writes outside the project — always prefer that APK when present.
$sourceApk = $null
if (Test-Path $altApk) {
    $sourceApk = $altApk
} elseif (Test-Path $apkPath) {
    $sourceApk = $apkPath
}

if (-not $buildOk -or $null -eq $sourceApk) {
    Write-Host "Build failed or APK not found." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $apkPath) | Out-Null
Copy-Item $sourceApk $apkPath -Force
Copy-Item $sourceApk $desktopApk -Force
Write-Host "APK ready:" -ForegroundColor Green
Write-Host "  $apkPath"
Write-Host "  $desktopApk"

if ($hasAdb) {
    Write-Host "Installing on device..." -ForegroundColor Green
    adb install -r $desktopApk
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Installation complete! Launching app..." -ForegroundColor Green
        adb shell monkey -p com.trufit.trufit_bodamma -c android.intent.category.LAUNCHER 1
    } else {
        Write-Host "Installation failed." -ForegroundColor Red
    }
} else {
    Write-Host "Build complete! You can find your APK at: $desktopApk" -ForegroundColor Green
    Write-Host "You can manually transfer this file to your phone to install it." -ForegroundColor Yellow
}
