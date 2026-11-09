#!/usr/bin/env bash

# Firebase Setup Verification Script
# Run this after enabling all Firebase services

echo "=========================================="
echo "Firebase Setup Verification"
echo "Project: legal-unity-network"
echo "=========================================="
echo ""

echo "1. Checking Firebase Authentication..."
firebase auth:export /dev/null --project=legal-unity-network > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Firebase Authentication is ENABLED"
else
    echo "❌ Firebase Authentication is NOT enabled"
fi
echo ""

echo "2. Checking Cloud Firestore..."
firebase firestore:databases:list --project=legal-unity-network > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Cloud Firestore is ENABLED"
else
    echo "❌ Cloud Firestore is NOT enabled"
fi
echo ""

echo "3. Deploying Firestore Security Rules..."
firebase deploy --only firestore:rules --project=legal-unity-network
if [ $? -eq 0 ]; then
    echo "✅ Firestore rules deployed successfully"
else
    echo "❌ Failed to deploy Firestore rules"
fi
echo ""

echo "4. Deploying Firebase Storage Rules..."
firebase deploy --only storage --project=legal-unity-network
if [ $? -eq 0 ]; then
    echo "✅ Storage rules deployed successfully"
else
    echo "⚠️  Storage might not be enabled yet"
    echo "   Go to: https://console.firebase.google.com/project/legal-unity-network/storage"
    echo "   Click 'Get Started' and enable Storage"
fi
echo ""

echo "=========================================="
echo "Verification Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. If Storage rules failed, enable Storage in Firebase Console"
echo "2. Run: flutter pub get"
echo "3. Run: flutter run (on Android device/emulator)"
echo ""
