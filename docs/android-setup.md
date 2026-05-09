# Android Setup Guide

Complete guide for setting up Android testing with Maestro.  
Steps are shown for both **Windows** and **macOS** where they differ.

---

## 1. Install Java

Maestro requires Java 11 or higher.

1. Download from https://adoptium.net
2. Run the installer

### Windows
During setup choose **"Add to PATH"** and **"Set JAVA_HOME"**.

### macOS
```bash
brew install --cask temurin
```

Verify on both platforms:

```bash
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

`adb` (Android Debug Bridge) is how Maestro talks to the emulator.

**First, find your SDK location:**  
Android Studio → **Settings → Appearance & Behavior → System Settings → Android SDK**  
Copy the **Android SDK Location** shown there.

### Windows

Run once in PowerShell:

```powershell
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$sdkPath", "User")
```

Restart your terminal, then verify:

```powershell
adb version
# Android Debug Bridge version 1.x.x
```

### macOS

Add to `~/.zshrc` (or `~/.bashrc`):

```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
```

Reload and verify:

```bash
source ~/.zshrc
adb version
# Android Debug Bridge version 1.x.x
```

---

## 4. Install Maestro CLI

### Windows

The automatic installer may not work in all network environments. Manual install is more reliable:

1. Go to: https://github.com/mobile-dev-inc/maestro/releases
2. Download the latest asset ending in `-win.zip`
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
```

> **Quick fix for current session only (no restart needed):**
> ```powershell
> $env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"
> ```

> **This project uses Maestro v2.5.1** installed at `C:\Users\nekoe\maestro\bin\`.

### macOS

Use the automatic installer:

```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

This adds Maestro to `~/.maestro/bin`. Add it to your PATH:

```bash
export PATH="$PATH:$HOME/.maestro/bin"
source ~/.zshrc
```

Or add the export line to `~/.zshrc` so it persists across sessions.

Verify:

```bash
maestro --version
# Maestro v2.x.x
```

---

## 5. Create an Android Emulator

1. Open Android Studio
2. Click **Device Manager** in the toolbar (phone icon)
3. Click **Create Device**
4. Pick a Pixel profile (any Pixel works — see tested profiles below)
5. Select system image: download **API 36** or **API 33+**
6. Click **Finish**

### Start from Android Studio

Click the **▶ Play** button next to your AVD in Device Manager.

### Start from the command line

**Windows** — add the `emulator` tool to PATH (run once):

```powershell
$emuPath = "$env:LOCALAPPDATA\Android\Sdk\emulator"
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$emuPath", "User")
$env:PATH = "$env:PATH;$emuPath"   # also apply to current session
```

**macOS** — add to `~/.zshrc`:

```bash
export PATH="$PATH:$HOME/Library/Android/sdk/emulator"
source ~/.zshrc
```

**Start the emulator (both platforms):**

```bash
# List all AVDs on this machine
emulator -list-avds
# Pixel_6_API_36
# Pixel_7_API_36
```

**Windows:**

```powershell
# Runs in the background — terminal returns immediately
Start-Process emulator -ArgumentList "-avd Pixel_6_API_36"
```

**macOS:**

```bash
# & runs it in the background
emulator -avd Pixel_7_API_36 &
```

Wait ~30–60 seconds for the home screen to appear, then verify:

```bash
adb devices
# emulator-5554   device   ← ready
```

> **Tested profiles:**
> - Windows: **Pixel 6**, API 36 (`emulator-5554`)
> - macOS: **Pixel 7**, API 36 (`emulator-5554`)
>
> Any Pixel profile on API 33+ works. If you use a different AVD, no flow changes are needed — Maestro targets the app by package name, not the device profile.

---

## 6. Get the APK

### Option A — Download automatically (recommended)

The script `scripts/download_apps.py` downloads the APK defined in `scripts/apps.yaml`.

**First-time setup:**

**Windows:**
```powershell
pip install pyyaml
Copy-Item scripts\apps.yaml.example scripts\apps.yaml
```

**macOS:**
```bash
pip3 install pyyaml
cp scripts/apps.yaml.example scripts/apps.yaml
```

Edit `scripts/apps.yaml` — set `source`, `filename`, and the matching `*_url`.

**Download:**

```bash
# Both platforms
python scripts/download_apps.py          # (use python3 on macOS if needed)

# Android only
python scripts/download_apps.py --android

# Force re-download even if file exists
python scripts/download_apps.py --android --force
```

For private GitHub releases, set your token first:

**Windows:**
```powershell
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxx"
python scripts/download_apps.py --android
```

**macOS:**
```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
python3 scripts/download_apps.py --android
```

The APK lands at `app/android/<filename>` (gitignored).

### Option B — Manual copy

**Windows:**
```powershell
Copy-Item C:\path\to\your.apk app\android\your.apk
```

**macOS:**
```bash
cp ~/Downloads/your.apk app/android/your.apk
```

---

## 7. Install the APK

```bash
# -r allows reinstalling over an existing version
adb install -r app/android/mda-2.2.0-25.apk
# Success
```

Open the app manually once to confirm it launches correctly.

---

## 8. Find Your App's Package Name

You need this for `appId:` in each flow file.

**Method 1 — from a running emulator (both platforms):**
```bash
adb shell pm list packages | grep saucelabs
# package:com.saucelabs.mydemoapp.android
```

**Method 2 — from the APK using `aapt`:**

Windows:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\<version>\aapt.exe" `
    dump badging app\android\your.apk | Select-String "package: name"
```

macOS:
```bash
$HOME/Library/Android/sdk/build-tools/<version>/aapt \
    dump badging app/android/your.apk | grep "package: name"
```

> **This project:** `com.saucelabs.mydemoapp.android`

---

## 9. Run Your First Test

### Windows

```powershell
# Add Maestro to PATH if not already done
$env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"

maestro test flows/android/TC-AND-001_login_valid.yaml `
    --env ANDROID_EMAIL=bod@example.com `
    --env PASSWORD=10203040
```

### macOS

```bash
maestro test flows/android/TC-AND-001_login_valid.yaml \
    --env ANDROID_EMAIL=bod@example.com \
    --env PASSWORD=10203040
```

Expected output (all green):

```
Running on emulator-5554
Launch app "com.saucelabs.mydemoapp.android" with clear state... COMPLETED
...
Assert that "Sauce Labs Backpack" is visible... COMPLETED
```

---

## 10. Run All Android Tests

### Windows

```powershell
maestro test flows/android `
    --env ANDROID_EMAIL=bod@example.com `
    --env PASSWORD=10203040
```

### macOS

```bash
maestro test flows/android \
    --env ANDROID_EMAIL=bod@example.com \
    --env PASSWORD=10203040
```

Expected: `5/5 Flows Passed`

---

## 11. Generate an HTML Test Report

**Install once (both platforms):**

```bash
pip install -r requirements.txt    # Windows: pip
pip3 install -r requirements.txt   # macOS: pip3
```

**Run tests with XML output:**

Windows:
```powershell
maestro test flows/android `
    --env ANDROID_EMAIL=bod@example.com `
    --env PASSWORD=10203040 `
    --format junit --output results.xml
```

macOS:
```bash
maestro test flows/android \
    --env ANDROID_EMAIL=bod@example.com \
    --env PASSWORD=10203040 \
    --format junit --output results.xml
```

**Convert to HTML:**

Windows:
```powershell
junit2html results.xml report.html
Start-Process report.html
```

macOS:
```bash
junit2html results.xml report.html
open report.html
```

---

## 12. Use the Helper Scripts (Windows only)

The PowerShell scripts in `scripts/` load `.env` automatically — no `--env` flags needed.

Copy `.env.example` to `.env` and fill in credentials:

```
ANDROID_EMAIL=bod@example.com
IOS_EMAIL=bob@example.com
PASSWORD=10203040
```

Then run:

```powershell
# Run one flow
.\scripts\run_flow.ps1 -Flow flows/android/TC-AND-001_login_valid.yaml -Platform android

# Run all Android flows
.\scripts\run_all.ps1 -Platform android

# Run a tag group
.\scripts\run_suite.ps1 -Platform android -Suite smoke
```

> **macOS users:** Use the `maestro test` commands from steps 9–11 directly.  
> The `.env` file pattern with PowerShell scripts is Windows-specific.

---

## Common Android Issues

| Error | Fix |
|-------|-----|
| `adb: command not found` | Add `platform-tools` to PATH (step 3) |
| `maestro: command not found` | Add Maestro `bin` to PATH (step 4) |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | `adb uninstall com.saucelabs.mydemoapp.android` first |
| `device offline` | Unplug/replug USB or restart emulator |
| `No connected devices` | `adb kill-server && adb start-server && adb devices` |
| `Command failed (tcp:7001): closed` | `pkill -f maestro-d && adb forward --remove-all && adb forward tcp:7001 tcp:7001` |
| App crashes on launch | `adb logcat` to see the crash stack trace |
| Flow launches wrong app | `appId:` cannot use env vars — hardcode the package name |
| `Unknown Property: timeout` on assertVisible | Use `extendedWaitUntil:` instead |
| `Invalid Command: clearText` | Use `eraseText: 100` instead |
| Android App Compatibility dialog blocks screen | APK not 16 KB page-aligned on Android 15 — add `tapOn: "OK" optional: true` after navigation steps |
