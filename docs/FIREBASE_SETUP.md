# Firebase Cloud Messaging (FCM) Integration Setup

RISE is built with local Android notifications enabled by default. This document describes the step-by-step process for activating future Firebase Cloud Messaging (FCM) push notifications.

---

## Current Status
- **Local Notifications**: Enabled via `flutter_local_notifications` for daily planning, study reminders, and evening reflections.
- **FCM**: Prepared in backend schema (`UserPreferences.fcm_token`, `FCM_ENABLED=false`) and disabled by default until valid credentials are provided.

---

## Step-by-Step Activation Guide

### 1. Create Firebase Project
1. Visit the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project**, name it `rise-personal-growth`.
3. Disable Google Analytics (optional).

### 2. Configure Android App
1. In Project Settings, click **Add App** -> **Android**.
2. Set Package Name: `com.rise.app`.
3. Download `google-services.json`.
4. Place `google-services.json` in:
   ```
   flutter_app/android/app/google-services.json
   ```

### 3. Add Firebase Gradle Plugins
In `flutter_app/android/build.gradle`:
```groovy
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```
In `flutter_app/android/app/build.gradle`:
```groovy
apply plugin: 'com.google.gms.google-services'
```

### 4. Enable Firebase Dependencies in Flutter
Add packages to `flutter_app/pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
```

### 5. Backend Configuration
1. Go to Firebase Console -> **Project Settings** -> **Service accounts**.
2. Click **Generate new private key** (downloads JSON credentials).
3. In `backend/.env`, set:
   ```env
   FCM_ENABLED=true
   FIREBASE_PROJECT_ID=rise-personal-growth
   FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
   ```
4. Update `app/services/notification_service.py` with `firebase-admin` initialization.
