# Quick Firebase Services Setup

You need to enable Firebase services via the Firebase Console. This takes about 5-10 minutes.

## Option 1: Automated via Console (Recommended)

**Open these links and follow the steps:**

### 1. Enable Authentication (2 minutes)
https://console.firebase.google.com/project/legal-unity-network/authentication/providers

Steps:
- Click "Get started"
- Enable "Phone" → Toggle ON → Save
- Enable "Google" → Toggle ON → Enter support email: naveen.bathina9@gmail.com → Save

### 2. Create Firestore Database (3 minutes)
https://console.firebase.google.com/project/legal-unity-network/firestore

Steps:
- Click "Create database"
- Choose "Start in production mode"
- Select location: "asia-south1 (Mumbai)" or closest to you
- Click "Enable"

### 3. Enable Firebase Storage (2 minutes)
https://console.firebase.google.com/project/legal-unity-network/storage

Steps:
- Click "Get started"
- Choose "Start in production mode"
- Use same location as Firestore
- Click "Done"

---

## After Enabling Services

### Deploy Security Rules

Run these commands in your terminal:

```powershell
# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy Storage security rules
firebase deploy --only storage
```

---

## Test the Setup

Once services are enabled and rules are deployed:

```powershell
# Test on Android (if you have an emulator or device)
flutter run -d <device-id>

# Or just verify the build works
flutter build apk --debug
```

---

## Quick Commands Reference

```powershell
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Check Firebase project status
firebase projects:list

# View Firestore rules
firebase firestore:rules:get
```

---

**Estimated time to complete:** 5-10 minutes

Once you've enabled these three services in the Firebase Console, let me know and I'll deploy the security rules and verify everything is working!
