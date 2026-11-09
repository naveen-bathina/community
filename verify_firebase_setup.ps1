# Firebase Setup Verification Script (PowerShell)
# Run this after enabling all Firebase services

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Firebase Setup Verification" -ForegroundColor Cyan
Write-Host "Project: legal-unity-network" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check Firebase Authentication
Write-Host "1. Checking Firebase Authentication..." -ForegroundColor Yellow
try {
    firebase auth:export null --project=legal-unity-network 2>$null | Out-Null
    Write-Host "✅ Firebase Authentication is ENABLED" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase Authentication is NOT enabled" -ForegroundColor Red
}
Write-Host ""

# Check Cloud Firestore
Write-Host "2. Checking Cloud Firestore..." -ForegroundColor Yellow
try {
    $result = firebase firestore:databases:list --project=legal-unity-network 2>&1
    if ($result -match "default") {
        Write-Host "✅ Cloud Firestore is ENABLED" -ForegroundColor Green
    } else {
        Write-Host "❌ Cloud Firestore is NOT enabled" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Cloud Firestore is NOT enabled" -ForegroundColor Red
}
Write-Host ""

# Deploy Firestore Security Rules
Write-Host "3. Deploying Firestore Security Rules..." -ForegroundColor Yellow
$firestoreResult = firebase deploy --only firestore:rules --project=legal-unity-network 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Firestore rules deployed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to deploy Firestore rules" -ForegroundColor Red
}
Write-Host ""

# Deploy Firebase Storage Rules
Write-Host "4. Deploying Firebase Storage Rules..." -ForegroundColor Yellow
$storageResult = firebase deploy --only storage --project=legal-unity-network 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Storage rules deployed successfully" -ForegroundColor Green
} else {
    Write-Host "⚠️  Storage deployment failed" -ForegroundColor Yellow
    Write-Host "   Make sure Storage is enabled at:" -ForegroundColor Yellow
    Write-Host "   https://console.firebase.google.com/project/legal-unity-network/storage" -ForegroundColor Cyan
    Write-Host "   Click 'Get Started' to enable Firebase Storage" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Verification Complete!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. If Storage failed, enable it in Firebase Console"
Write-Host "2. Ensure Android emulator or device is connected"
Write-Host "3. Run: flutter devices (to see available devices)"
Write-Host "4. Run: flutter run -d <device-id>"
Write-Host ""
