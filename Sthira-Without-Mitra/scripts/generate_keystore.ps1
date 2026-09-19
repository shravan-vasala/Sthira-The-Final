# generate_keystore.ps1
# Creates a local keystore for Android signing

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " TruFit Bodamma Keystore Generator" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$alias = Read-Host "Enter key alias (default: upload)"
if ([string]::IsNullOrWhiteSpace($alias)) { $alias = "upload" }

$password = Read-Host "Enter keystore password (default: android)"
if ([string]::IsNullOrWhiteSpace($password)) { $password = "android" }

$keystorePath = "..\android\app\upload-keystore.jks"

Write-Host "Generating keystore..." -ForegroundColor Yellow
# Run keytool (must be in PATH, usually installed with JDK)
keytool -genkey -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias $alias -storepass $password -keypass $password -dname "CN=TruFit Bodamma, OU=TruFit, O=Bodamma, L=Local, S=State, C=US"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Keystore generated successfully at $keystorePath" -ForegroundColor Green
    Write-Host "To use this keystore for release builds, create android/key.properties:" -ForegroundColor Cyan
    Write-Host "storePassword=$password" -ForegroundColor Cyan
    Write-Host "keyPassword=$password" -ForegroundColor Cyan
    Write-Host "keyAlias=$alias" -ForegroundColor Cyan
    Write-Host "storeFile=upload-keystore.jks" -ForegroundColor Cyan
} else {
    Write-Host "❌ Failed to generate keystore. Ensure Java 'keytool' is installed and in your PATH." -ForegroundColor Red
}
