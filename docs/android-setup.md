# Android Setup Guide

Complete guide for setting up Android testing with Maestro on Windows.

---

## 1. Install Java

Maestro requires Java 11 or higher.

1. Download from https://adoptium.net
2. Run the installer (choose "Add to PATH" and "Set JAVA_HOME" during setup)
3. Verify:

```powershell
java -version
# openjdk version "11.x.x" or higher
```

---

## 2. Install Android Studio

1. Download from https://developer.android.com/studio
2. Run the installer and follow the setup wizard
3. In the **SDK Components Setup** screen, make sure these are checked:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)

---

## 3. Add `adb` to your PATH

`adb` is the Android Debug Bridge — Maestro uses it to communicate with devices.

1. Find your SDK location:
   - Android Studio → **Settings → Appearance & Behavior → System Settings → Android SDK**
   - Copy the **Android SDK Location** (e.g. `C:\Users\YourName\AppData\Local\Android\Sdk`)

2. Add `platform-tools` to PATH (run once in PowerShell):

```powershell
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$sdkPath", "User")
```

3. Restart your terminal, then verify:

```powershell
adb version
# Android Debug Bridge version 1.x.x
```

---

## 4. Install Maestro CLI (Windows)

The automatic installer may not work in all network environments. Manual install is reliable:

1. Go to: https://github.com/mobile-dev-inc/maestro/releases
2. Download the latest `maestro_win.zip` (or the asset ending in `-win.zip`)
3. Extract to `C:\Users\<YourName>\maestro\`
4. Add to PATH permanently:

```powershell
[Environment]::SetEnvironmentVariable(
    "PATH",
    "$env:PATH;$env:USERPROFILE\maestro\bin",
    "User"
)
```

5. Restart your terminal, then verify:

```powershell
maestro --version
# Maestro v2.x.x
```

> **Quick fix for current session only (no restart needed):**
> ```powershell
> $env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"
> ```

> **This project uses Maestro v2.5.1** installed at `C:\Users\nekoe\maestro\bin\`.

---

## 5. Create an Android Emulator

1. Open Android Studio
2. Click **Device Manager** in the toolbar (phone icon)
3. Click **Create Device**
4. Pick **Pixel 7** (recommended — tested profile)
5. Select system image: download **API 36** or **API 33+**
6. Click **Finish**

Start the emulator:
- Click the **▶ Play** button next to your AVD
- Wait until the Android home screen appears (~1 minute first time)

Verify Maestro can see it:

```powershell
adb devices
# emulator-5554   device   ← ready
```

> **This project was tested on:** Pixel_7_API_36 emulator (`emulator-5554`).

---

## 6. Get the APK

### Option A — Download automatically (recommended)

The script `scripts/download_apps.py` downloads the APK defined in `scripts/apps.yaml`.

**First-time setup:**

```powershell
# 1. Install the only dependency
pip install pyyaml

# 2. Copy the example config and fill in URLs
Copy-Item scripts\apps.yaml.example scripts\apps.yaml
# Edit scripts\apps.yaml — set source, filename, and the matching *_url
```

**Download:**

```powershell
# Both platforms
python scripts/download_apps.py

# Android only
python scripts/download_apps.py --android

# Force re-download even if file already exists
python scripts/download_apps.py --android --force
```

For private GitHub releases, set your token first:

```powershell
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxx"
python scripts/download_apps.py --android
```

The APK lands at `app/android/<filename>` (gitignored).

### Option B — Manual copy

Place the APK directly into `app/android/`:

```powershell
Copy-Item C:\path\to\your.apk app\android\your.apk
```

---

## 7. Install the APK

```powershell
# -r allows reinstalling over an existing version
adb install -r app\android\mda-2.2.0-25.apk
# Success
```

Open the app manually once to confirm it launches correctly.

---

## 7. Find Your App's Package Name

You need this for `appId:` in each flow file.

**Method 1 — from the APK (requires `aapt` in SDK build-tools):**
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\<version>\aapt.exe" `
    dump badging builds\android\your.apk | Select-String "package: name"
```

**Method 2 — from a running emulator:**
```powershell
adb shell pm list packages | Select-String "yourapp"
```

**Method 3 — from source code:**
Open `android/app/build.gradle` and look for `applicationId`.

> **This project:** `com.saucelabs.mydemoapp.android`

---

## 8. Run Your First Test

```powershell
# Add Maestro to PATH if not already done
$env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"

# Run TC-AND-001
maestro test flows/android/TC-AND-001_login_valid.yaml `
    --env "EMAIL=bod@example.com" `
    --env "PASSWORD=10203040"
```

Expected output (all green):
```
Running on emulator-5554
Launch app "com.saucelabs.mydemoapp.android" with clear state... COMPLETED
...
Assert that "Products" is visible... COMPLETED
```

---

## 9. Run All Android Tests

```powershell
maestro test flows/android `
    --env "EMAIL=bod@example.com" `
    --env "PASSWORD=10203040"
```

Expected: `5/5 Flows Passed`

---

## Common Android Issues

| Error | Fix |
|-------|-----|
| `adb: command not found` | Add `platform-tools` to PATH (step 3 above) |
| `maestro: command not found` | Add `maestro\bin` to PATH (step 4 above) |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | `adb uninstall com.your.app` first, then re-install |
| `device offline` | Unplug/replug USB or restart emulator |
| `No connected devices` | `adb kill-server && adb start-server`, then `adb devices` |
| App crashes on launch | `adb logcat` to see the crash stack trace |
| Flow launches wrong app / Android home screen | `appId:` cannot use env vars — hardcode the package name |
| `Unknown Property: timeout` | Use `extendedWaitUntil:` instead of `assertVisible: timeout:` |
| `Invalid Command: clearText` | Use `eraseText: 100` instead |
