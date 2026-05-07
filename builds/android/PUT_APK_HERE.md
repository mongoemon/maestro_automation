# Android Builds

Place your Android APK file in this folder.

## How to get an APK

### From Android Studio
1. Open your project in Android Studio
2. Menu: **Build → Build Bundle(s) / APK(s) → Build APK(s)**
3. Click **locate** in the notification that appears
4. Copy the `.apk` file here

### From a developer / CI pipeline
Ask your developer for a **debug** or **staging** APK, or download the artifact from your CI pipeline.

## Install the APK to your device/emulator

```powershell
# From the project root
adb install builds\android\your-app.apk
```

## Naming convention

Use a consistent name so scripts can find it:

```
app-debug.apk       ← debug build
app-staging.apk     ← staging build
app-release.apk     ← release/production build
```

## Notes

- Re-run `adb install` every time you get a new build
- If install fails with `INSTALL_FAILED_VERSION_DOWNGRADE`, uninstall first:
  `adb uninstall com.yourapp.packagename`
- APK files are gitignored — never commit binary builds to this repo
