# FieldPilot — Android APK Build Instructions

This guide explains how to generate ready-to-install Android APKs for **FieldPilot**.

---

## 1. Prerequisites

Before generating the APK, ensure:
1. Flutter SDK is in your system PATH (`flutter --version`).
2. Android SDK with Build Tools is installed via Android Studio.
3. Google Maps API key is configured in `mobile/android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_KEY_HERE" />
   ```

---

## 2. Build Debug APK (For Immediate Device Testing)

The debug build does not require cryptographic keystore signing and can be installed immediately on any Android phone with "Install from Unknown Sources" enabled.

### Run Command:
```powershell
cd "e:\app mo\mobile"
flutter build apk --debug
```

### Output File Location:
```
mobile/build/app/outputs/flutter-apk/app-debug.apk
```

### Install onto Connected Phone:
```powershell
flutter install
# Or via ADB directly:
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 3. Build Production Release APK

To create an optimized, minified production build:

### Step 3.1: Generate a Release Keystore (If not already created)
```powershell
keytool -genkey -v -keystore fieldpilot-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fieldpilot
```

### Step 3.2: Build the Release APK
```powershell
cd "e:\app mo\mobile"
flutter build apk --release
```

### Output File Location:
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. Build Split Per ABI APKs (Recommended for Small File Sizes)

If you want smaller APK downloads tailored to specific CPU architectures (ARM64, ARMv7):
```powershell
flutter build apk --split-per-abi
```
Generated APK files:
- `app-arm64-v8a-release.apk` (For 90%+ modern Android devices)
- `app-armeabi-v7a-release.apk` (For older 32-bit devices)
- `app-x86_64-release.apk` (For Intel/AMD Chromebooks or Emulators)

---

## 5. Troubleshooting Common Build Issues

1. **Gradle Memory Limit:**
   If the build runs out of memory, add the following to `mobile/android/gradle.properties`:
   ```properties
   org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
   ```

2. **Network Security Config for Local IP:**
   If your device cannot connect to a local HTTP backend (`http://192.168.X.X:8000`), ensure `android:usesCleartextTraffic="true"` is present in the `<application>` tag of `AndroidManifest.xml`.
