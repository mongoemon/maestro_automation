# Maestro Mobile Automation

Step-by-step guide for beginners to set up and run mobile UI tests using [Maestro](https://maestro.mobile.dev/).

**Additional docs:**
- [Maestro Reference](docs/maestro-reference.md) — CLI commands, YAML command reference, troubleshooting
- [Project Structure](docs/project-structure.md) — directory layout, subflow architecture, env vars
- [Writing Flows](docs/writing-flows.md) — patterns and best practices for authoring flows
- [Android Setup](docs/android-setup.md) · [iOS Setup](docs/ios-setup.md)

---

## Table of Contents

1. [What is Maestro?](#1-what-is-maestro)
2. [Prerequisites](#2-prerequisites)
3. [Install Maestro CLI](#3-install-maestro-cli)
4. [Project Structure](#4-project-structure)
5. [First-Time Setup](#5-first-time-setup)
6. [Get the App Builds](#6-get-the-app-builds)
7. [Connect a Device or Emulator](#7-connect-a-device-or-emulator)
8. [Run Tests — Android](#8-run-tests--android)
9. [Run Tests — iOS](#9-run-tests--ios)
10. [Run Test Suites](#10-run-test-suites)
11. [Read the Results](#11-read-the-results)
12. [Write Your Own Flow](#12-write-your-own-flow)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. What is Maestro?

Maestro is a mobile UI testing framework. You write test steps in simple YAML files called **flows**, and Maestro drives a real device or emulator/simulator to execute them — tapping buttons, typing text, and asserting what's on screen.

**No code required.** A flow looks like this:

```yaml
appId: com.example.app
---
- launchApp
- tapOn: "Login"
- inputText: "user@example.com"
- extendedWaitUntil:
    visible:
      text: "Welcome"
    timeout: 8000
```

---

## 2. Prerequisites

Install these before anything else.

| Tool | Why you need it | Install link |
|------|----------------|--------------|
| **Java 11+** | Maestro runs on the JVM | https://adoptium.net |
| **Android Studio** | Android emulator + `adb` tool | https://developer.android.com/studio |
| **Xcode 14+** | iOS simulator *(Mac only)* | Mac App Store |
| **Python 3 + pyyaml** | Download app builds | `pip install pyyaml` |
| **Git** | Clone / version control | https://git-scm.com |

> **Windows users:** iOS testing requires a Mac. You can run Android tests on Windows.

Verify Java is installed:

```bash
java -version
# Should print: openjdk version "11.x.x" or higher
```

---

## 3. Install Maestro CLI

### macOS / Linux

```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

Restart your terminal, then verify:

```bash
maestro --version
```

### Windows

1. Download the latest release zip from: https://github.com/mobile-dev-inc/maestro/releases  
   (look for the asset named `maestro_win.zip`)
2. Extract to `C:\Users\<YourName>\maestro\`
3. Add to your PATH permanently:

```powershell
[Environment]::SetEnvironmentVariable(
    "PATH",
    "$env:PATH;$env:USERPROFILE\maestro\bin",
    "User"
)
```

4. Restart your terminal, then verify:

```powershell
maestro --version
```

> **Tip:** If `maestro` is not recognized in the current session, add it temporarily:
> ```powershell
> $env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"
> ```

---

## 4. Project Structure

> For a deeper explanation of every file and how the pieces fit together, see [docs/project-structure.md](docs/project-structure.md).

```
maestro_automation/
│
├── app/                        ← App binaries (gitignored)
│   ├── android/                ←   Android APK
│   └── ios/                    ←   iOS .app (simulator) or .ipa (device)
│
├── flows/                      ← All test flows (YAML)
│   ├── android/                ←   Android-specific flows
│   │   ├── TC-AND-001_login_valid.yaml
│   │   ├── TC-AND-002_products_after_login.yaml
│   │   ├── TC-AND-003_login_error_empty_username.yaml
│   │   ├── TC-AND-004_login_error_empty_password.yaml
│   │   └── TC-AND-005_logout.yaml
│   ├── ios/                    ←   iOS-specific flows
│   │   ├── TC-IOS-001_login_valid.yaml
│   │   ├── TC-IOS-002_products_after_login.yaml
│   │   ├── TC-IOS-003_login_error_empty_username.yaml
│   │   ├── TC-IOS-004_login_error_empty_password.yaml
│   │   ├── TC-IOS-005_logout.yaml
│   │   └── subflows/           ←   iOS-specific helpers
│   │       ├── navigate_to_login.yaml
│   │       └── perform_login.yaml
│   └── subflows/               ←   Shared helpers (used by Android)
│       ├── navigate_to_login.yaml
│       ├── perform_login.yaml
│       └── common_actions.yaml
│
├── scripts/                    ← PowerShell helper scripts
│   ├── run_all.ps1             ← Run every flow for a platform
│   ├── run_suite.ps1           ← Run a named suite (smoke, auth, etc.)
│   ├── run_flow.ps1            ← Run one specific flow
│   ├── download_apps.py        ← Download app binaries
│   └── apps.yaml               ← Build download config (copy from apps.yaml.example)
│
├── reports/                    ← JUnit XML reports (auto-generated with -Report flag)
│
├── docs/
│   └── ios-setup.md            ← Detailed iOS setup guide
│
├── .env                        ← Your credentials (DO NOT commit)
└── .env.example                ← Template — copy this to .env
```

---

## 5. First-Time Setup

**Step 1 — Copy the environment template**

```bash
# macOS / Linux
cp .env.example .env

# Windows (PowerShell)
Copy-Item .env.example .env
```

**Step 2 — Edit `.env` with your credentials**

```env
ANDROID_APP_ID=com.saucelabs.mydemoapp.android
IOS_APP_ID=com.saucelabs.mydemo.app.ios
IOS_EMAIL=bob@example.com
ANDROID_EMAIL=bod@example.com
PASSWORD=10203040
```

> The demo app uses different test accounts per platform:
> - **Android:** `bod@example.com` — tap the shortcut to auto-fill both username and password
> - **iOS:** `bob@example.com` — tap the shortcut to fill username, then type password manually

> **Note:** `appId:` in flow files cannot use env vars — it is always hardcoded.

---

## 6. Get the App Builds

App binaries are **not committed** to git. Download them with the provided script.

**Step 1 — Copy and configure `apps.yaml`**

```bash
cp scripts/apps.yaml.example scripts/apps.yaml
```

The default config uses the official SauceLabs demo app releases. No edits needed to get started.

**Step 2 — Download**

```bash
# Download both platforms
python scripts/download_apps.py

# Or download one at a time
python scripts/download_apps.py --android
python scripts/download_apps.py --ios
```

Files land at `app/android/<filename>` and `app/ios/<filename>`.

**iOS simulator build — extra step:**

The iOS download is a `.zip`. Extract it before installing:

```bash
unzip app/ios/SauceLabs-Demo-App.Simulator.zip -d app/ios/
# App bundle lands at: app/ios/Payload/My Demo App.app
```

---

## 7. Connect a Device or Emulator

### Android Emulator

1. Open **Android Studio → Device Manager**
2. Create a device if needed (**Pixel 7, API 33+** recommended)
3. Press **▶ Play** to start it

Verify it's connected:

```bash
adb devices
# emulator-5554   device
```

Install the APK:

```bash
adb install -r app/android/mda-2.2.0-25.apk
```

### Android Physical Device

1. Enable **Developer Options**: Settings → About Phone → tap **Build Number** 7 times
2. Enable **USB Debugging** in Developer Options
3. Connect via USB and accept the "Allow USB Debugging" dialog

```bash
adb devices
# ABC123XYZ   device

adb install -r app/android/mda-2.2.0-25.apk
```

### iOS Simulator *(Mac only)*

```bash
# List available simulators
xcrun simctl list devices available

# Boot one
xcrun simctl boot "iPhone 16 Pro"

# Open the Simulator app
open -a Simulator

# Install the app (after extracting the zip — see §6)
xcrun simctl install booted "app/ios/Payload/My Demo App.app"
```

See [docs/ios-setup.md](docs/ios-setup.md) for the full iOS setup guide.

---

## 8. Run Tests — Android

Make sure the emulator is running and the APK is installed, then:

```bash
# Run a single flow
maestro test flows/android/TC-AND-001_login_valid.yaml \
    --env ANDROID_EMAIL=bod@example.com \
    --env PASSWORD=10203040

# Run all Android flows
maestro test flows/android/ \
    --env ANDROID_EMAIL=bod@example.com \
    --env PASSWORD=10203040
```

**Using the helper script (reads from `.env` automatically):**

```powershell
# Single flow
.\scripts\run_flow.ps1 -Flow flows/android/TC-AND-001_login_valid.yaml -Platform android

# All Android flows
.\scripts\run_all.ps1 -Platform android

# With JUnit report
.\scripts\run_all.ps1 -Platform android -Report
```

**Expected output — all passing:**

```
[Passed] TC-AND-001: Login with valid credentials (35s)
[Passed] TC-AND-002: Products list is shown after login (51s)
[Passed] TC-AND-003: Username field shows error when left empty (28s)
[Passed] TC-AND-004: Password field shows error when left empty (32s)
[Passed] TC-AND-005: Logout returns Login option to menu (42s)
```

---

## 9. Run Tests — iOS

Make sure the simulator is booted and the app is installed, then:

```bash
# Run a single flow
maestro test flows/ios/TC-IOS-001_login_valid.yaml \
    --env IOS_EMAIL=bob@example.com \
    --env PASSWORD=10203040

# Run all iOS flows
maestro test flows/ios/ \
    --env IOS_EMAIL=bob@example.com \
    --env PASSWORD=10203040
```

**Using the helper script:**

```powershell
# Single flow
.\scripts\run_flow.ps1 -Flow flows/ios/TC-IOS-001_login_valid.yaml -Platform ios

# All iOS flows
.\scripts\run_all.ps1 -Platform ios

# With JUnit report
.\scripts\run_all.ps1 -Platform ios -Report
```

**Expected output — all passing:**

```
[Passed] TC-IOS-001: Login with valid credentials
[Passed] TC-IOS-002: Products list is shown after login
[Passed] TC-IOS-003: Username field shows error when left empty
[Passed] TC-IOS-004: Password field shows error when left empty
[Passed] TC-IOS-005: Logout returns Login option to menu
```

---

## 10. Run Test Suites

Filter by tag using the helper script:

```powershell
# Smoke tests (fast, critical paths only)
.\scripts\run_suite.ps1 -Suite smoke -Platform android
.\scripts\run_suite.ps1 -Suite smoke -Platform ios

# Auth flows only
.\scripts\run_suite.ps1 -Suite auth -Platform android

# Validation flows only
.\scripts\run_suite.ps1 -Suite validation -Platform android

# Full regression (all tags)
.\scripts\run_suite.ps1 -Suite regression -Platform android
```

Available tags:

| Tag | Flows included |
|-----|---------------|
| `smoke` | TC-001, TC-002, TC-005 |
| `auth` | TC-001, TC-002, TC-003, TC-004, TC-005 |
| `validation` | TC-003, TC-004 |
| `regression` | All flows |

---

## 11. Read the Results

**In the terminal:** Each step prints `COMPLETED`, `WARNED` (optional element not found), or `FAILED`.

**Debug artifacts on failure:** Maestro saves screenshots and logs to:

```
# macOS / Linux
~/.maestro/tests/<timestamp>/

# Windows
C:\Users\<name>\.maestro\tests\<timestamp>\
```

The failure screenshot (named with ❌) shows exactly what was on screen when the test failed.

**JUnit XML report** (generated with `-Report` flag or `--format junit`):

```
reports/
└── report-android.xml
└── report-ios.xml
```

Import this into CI systems (GitHub Actions, Jenkins, etc.) or open in any JUnit viewer.

**Named screenshots** (defined in flows with `takeScreenshot:`):

Each flow captures `start` and `complete` screenshots. They are saved in the directory where you ran `maestro`, e.g.:

```
TC-AND-001_start.png
TC-AND-001_complete.png
```

---

## 12. Write Your Own Flow

Create a new YAML file in `flows/android/` or `flows/ios/`.

**Minimal template:**

```yaml
appId: com.yourcompany.yourapp     # MUST be hardcoded — env vars do not work here
name: "TC-XXX: What this test does"
tags:
  - android
  - smoke
env:
  ANDROID_EMAIL: ${ANDROID_EMAIL}
  PASSWORD: ${PASSWORD}
onFlowStart:
  - takeScreenshot: TC-XXX_start
onFlowComplete:
  - takeScreenshot: TC-XXX_complete
---
- launchApp:
    clearState: true

- waitForAnimationToEnd

- runFlow:
    file: ../subflows/navigate_to_login.yaml
    env:
      APP_ID: com.yourcompany.yourapp

- tapOn: "Some Button"

- extendedWaitUntil:
    visible:
      text: "Expected Result"
    timeout: 8000
```

**Common commands:**

| Command | What it does |
|---------|-------------|
| `launchApp: clearState: true` | Restart the app with fresh state |
| `tapOn: "Text"` | Tap by visible text |
| `tapOn: id: "resource_id"` | Tap by resource/accessibility ID *(most reliable)* |
| `tapOn: point: "50%, 34%"` | Tap by screen percentage coordinates |
| `tapOn: text: "X" index: 1` | Tap the second element matching text X |
| `tapOn: text: "X" optional: true` | Tap only if element exists, skip otherwise |
| `inputText: "hello"` | Type text into focused field |
| `eraseText: 100` | Erase up to 100 characters from focused field |
| `extendedWaitUntil: visible: text: "..." timeout: N` | Wait up to N ms for element |
| `assertVisible: text: "X"` | Fail immediately if element is not on screen |
| `assertVisible: text: "X" optional: true` | Warn but don't fail if not found |
| `scroll` | Scroll down |
| `waitForAnimationToEnd` | Wait for transitions to finish |
| `takeScreenshot: name` | Save a named screenshot |
| `runFlow: file: ../other.yaml` | Execute another flow as a step |

**Using environment variables:**

```yaml
env:
  ANDROID_EMAIL: ${ANDROID_EMAIL}   # declare variables the flow needs
---
- tapOn: ${ANDROID_EMAIL}           # use in steps
```

**Finding element IDs:**

```bash
# Android — dump UI hierarchy
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml

# Or use Maestro Studio for a live interactive inspector
maestro studio
```

---

## 13. Troubleshooting

**`maestro: command not found`**  
→ Maestro is not on PATH.
```bash
# macOS/Linux — add to shell profile (~/.zshrc or ~/.bashrc)
export PATH="$PATH:$HOME/.maestro/bin"

# Windows (current session)
$env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"
```

**`adb devices` shows nothing**  
→ Enable USB Debugging on your phone. Try a different cable (data cable, not charge-only).

**`INSTALL_FAILED_VERSION_DOWNGRADE`**  
→ Uninstall the existing app first: `adb uninstall com.saucelabs.mydemoapp.android`

**`Command failed (tcp:7001): closed` on Android**  
→ Stale Maestro daemon. Kill it and reset the port forward:
```bash
pkill -f maestro-d
adb forward --remove-all
adb forward tcp:7001 tcp:7001
# Then re-run your test
```

**Android App Compatibility dialog blocks the test**  
→ The SauceLabs demo APK is not 16 KB aligned — Android 15 emulators show this warning on every screen. The flows handle it automatically with optional `tapOn: "OK"` steps. If a new screen triggers it, add another optional OK tap before your assertion.

**`Element not found: bob@example.com` on Android**  
→ The Android app uses `bod@example.com` (not `bob`). Make sure your `.env` has `ANDROID_EMAIL=bod@example.com` and you are passing `--env ANDROID_EMAIL=bod@example.com`.

**iOS password field stays empty after login**  
→ The iOS perform_login subflow uses a credential shortcut (`tapOn: "${IOS_EMAIL}"`) to fill the username, then taps the password field by coordinate. If this breaks, it is usually because the screen layout shifted — check the `y≈53%` coordinate in `flows/ios/subflows/perform_login.yaml`.

**`Assertion is false: "Products" is visible` after login**  
→ The `"Products"` heading is not exposed in the iOS accessibility tree. The flows assert `"Sauce Labs Backpack"` (a product list item) instead. If you see this error, a product card element name may have changed.

**`Unable to find a booted simulator` (iOS)**  
→ Boot a simulator first:
```bash
xcrun simctl boot "iPhone 16 Pro"
open -a Simulator
```

**Flow passes locally but fails in CI**  
→ Ensure the emulator is fully booted before running Maestro. Wait for `sys.boot_completed=1`:
```bash
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done
```

---

## Quick Reference

```bash
# ── Android ──────────────────────────────────────────────────────────
# Install APK
adb install -r app/android/mda-2.2.0-25.apk

# Run one flow
maestro test flows/android/TC-AND-001_login_valid.yaml \
    --env ANDROID_EMAIL=bod@example.com --env PASSWORD=10203040

# Run all Android flows
maestro test flows/android/ \
    --env ANDROID_EMAIL=bod@example.com --env PASSWORD=10203040

# ── iOS (Mac only) ────────────────────────────────────────────────────
# Boot simulator and install app
xcrun simctl boot "iPhone 16 Pro" && open -a Simulator
xcrun simctl install booted "app/ios/Payload/My Demo App.app"

# Run one flow
maestro test flows/ios/TC-IOS-001_login_valid.yaml \
    --env IOS_EMAIL=bob@example.com --env PASSWORD=10203040

# Run all iOS flows
maestro test flows/ios/ \
    --env IOS_EMAIL=bob@example.com --env PASSWORD=10203040

# ── Inspect ───────────────────────────────────────────────────────────
# Live element inspector
maestro studio

# Dump Android UI hierarchy
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml
```
