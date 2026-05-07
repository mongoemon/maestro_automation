# Maestro Mobile Automation

Step-by-step guide for beginners to set up and run mobile UI tests using [Maestro](https://maestro.mobile.dev/).

---

## Table of Contents

1. [What is Maestro?](#1-what-is-maestro)
2. [Prerequisites](#2-prerequisites)
3. [Install Maestro CLI](#3-install-maestro-cli)
4. [Project Structure](#4-project-structure)
5. [First-Time Setup](#5-first-time-setup)
6. [Where to Put Your App Build](#6-where-to-put-your-app-build)
7. [Connect a Device or Emulator](#7-connect-a-device-or-emulator)
8. [Run Your First Test](#8-run-your-first-test)
9. [Run Test Suites](#9-run-test-suites)
10. [Read the Results](#10-read-the-results)
11. [Write Your Own Flow](#11-write-your-own-flow)
12. [Troubleshooting](#12-troubleshooting)

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
| **Git** | Clone / version control | https://git-scm.com |

> **Windows users:** iOS testing requires a Mac. You can run Android tests on Windows.

Verify Java is installed:

```powershell
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

The automatic installer may require a proxy or manual steps. If `iwr ... | iex` fails, install manually:

1. Download the latest release zip from: https://github.com/mobile-dev-inc/maestro/releases  
   (look for `maestro_win.zip` or the assets named `maestro-*`)
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

> **Tip (this session):** Maestro was installed at `C:\Users\nekoe\maestro\bin\maestro.bat`.  
> If `maestro` is not recognized, add it to PATH for the current session:
> ```powershell
> $env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"
> ```

---

## 4. Project Structure

```
maestro_automation/
│
├── builds/                     ← Put your app builds here
│   ├── android/                ←   Android APK files
│   └── ios/                    ←   iOS .app (simulator) or .ipa (device)
│
├── flows/                      ← All test flows (YAML)
│   ├── android/                ←   Android-specific flows
│   │   ├── TC-AND-001_login_valid.yaml
│   │   ├── TC-AND-002_products_after_login.yaml
│   │   ├── TC-AND-003_login_error_empty_username.yaml
│   │   ├── TC-AND-004_login_error_empty_password.yaml
│   │   └── TC-AND-005_logout.yaml
│   ├── ios/                    ←   iOS-specific flows (same test cases)
│   │   └── TC-IOS-001 ... TC-IOS-005
│   └── subflows/               ←   Reusable helper flows
│       ├── navigate_to_login.yaml
│       ├── perform_login.yaml
│       └── common_actions.yaml
│
├── scripts/                    ← PowerShell helper scripts
│   ├── run_all.ps1             ← Run every flow for a platform
│   ├── run_suite.ps1           ← Run a named suite (smoke, auth, etc.)
│   └── run_flow.ps1            ← Run one specific flow
│
├── reports/                    ← Test results (auto-generated)
│
├── .env                        ← Your credentials (DO NOT commit)
└── .env.example                ← Template — copy this to .env
```

---

## 5. First-Time Setup

**Step 1 — Copy the environment template**

```powershell
Copy-Item .env.example .env
```

**Step 2 — Edit `.env` with your app details**

Open `.env` in any text editor:

```env
ANDROID_APP_ID=com.saucelabs.mydemoapp.android
IOS_APP_ID=com.saucelabs.mydemo.app.ios
EMAIL=bod@example.com
PASSWORD=10203040
```

> **Note:** The `APP_ID` values in `.env` are used by the run scripts only.  
> Each flow file hardcodes its own `appId:` — Maestro does not substitute env vars in the `appId:` header.

> Find your app IDs:
> - **Android APK:** `aapt dump badging your.apk | grep package`
> - **iOS IPA:** Unzip the IPA and read `Payload/YourApp.app/Info.plist`

---

## 6. Where to Put Your App Build

Place your compiled app files in the `builds/` folder before running tests.

### Android (APK)

```
builds/
└── android/
    └── mda-2.2.0-25.apk       ← your APK here
```

Get your APK from:
- Android Studio: **Build → Build Bundle(s)/APK(s) → Build APK(s)**
- CI output: download the artifact from your pipeline
- From a developer: ask for a debug or staging APK

Install it to your device/emulator:

```powershell
adb install -r builds\android\mda-2.2.0-25.apk
# -r flag allows reinstalling over an existing version
```

> You only need to install once per build. Re-install when the app is updated.

---

### iOS — Simulator (`.app`)

```
builds/
└── ios/
    └── YourApp.app         ← .app bundle here (it's a folder, not a file)
```

Install it to the running simulator:

```bash
xcrun simctl install booted builds/ios/YourApp.app
```

---

### iOS — Real Device (`.ipa`)

```
builds/
└── ios/
    └── SauceLabs-Demo-App.ipa   ← your IPA here
```

Install it to a connected device:

```bash
# Using ios-deploy (install once: npm install -g ios-deploy)
ios-deploy --bundle builds/ios/SauceLabs-Demo-App.ipa
```

> **Tip:** For daily automation, simulator builds are much faster to install and reset.

---

## 7. Connect a Device or Emulator

### Android Emulator

1. Open **Android Studio**
2. Go to **Device Manager** (toolbar icon)
3. Click **Create Device** if you don't have one — **Pixel 7, API 36** recommended
4. Press the **▶ Play** button to start it

Verify it's connected:

```powershell
adb devices
# Should show: emulator-5554   device
```

### Android Physical Device

1. Enable **Developer Options** on your phone:
   - Settings → About Phone → tap **Build Number** 7 times
2. Enable **USB Debugging** in Developer Options
3. Connect via USB cable
4. Accept the "Allow USB Debugging" dialog on your phone

```powershell
adb devices
# Should show: ABC123XYZ   device
```

### iOS Simulator *(Mac only)*

```bash
xcrun simctl list devices available
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator
```

### iOS Physical Device *(Mac only)*

1. Connect your iPhone via USB and trust the computer
2. In Xcode: **Window → Devices and Simulators** to confirm it appears

---

## 8. Run Your First Test

Make sure your device/emulator is running and the app is installed, then:

```powershell
# Add Maestro to PATH if needed
$env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"

# Run a single flow (pass credentials as --env)
maestro test flows/android/TC-AND-001_login_valid.yaml `
    --env "EMAIL=bod@example.com" `
    --env "PASSWORD=10203040"
```

You will see Maestro take control of the device and execute each step. Green = passed, red = failed with a screenshot saved to `C:\Users\<name>\.maestro\tests\<timestamp>\`.

**Or use the helper script (reads from `.env` automatically):**

```powershell
.\scripts\run_flow.ps1 -Flow flows/android/TC-AND-001_login_valid.yaml
```

---

## 9. Run Test Suites

Run all flows for a platform:

```powershell
# All Android tests
maestro test flows/android `
    --env "EMAIL=bod@example.com" `
    --env "PASSWORD=10203040"

# All iOS tests (Mac only)
maestro test flows/ios `
    --env "EMAIL=bod@example.com" `
    --env "PASSWORD=10203040"
```

Run by tag using the helper script:

```powershell
# Smoke tests (fast, critical paths only)
.\scripts\run_suite.ps1 -Suite smoke -Platform android

# Auth flows only
.\scripts\run_suite.ps1 -Suite auth -Platform android

# Full regression
.\scripts\run_all.ps1 -Platform android
```

---

## 10. Read the Results

**In the terminal:** Each step prints COMPLETED, WARNED (optional element not found), or FAILED.

**Debug artifacts:** On failure, Maestro saves screenshots and logs to:
```
C:\Users\<name>\.maestro\tests\<timestamp>\
```
The failure screenshot (named with ❌) shows exactly what was on screen when the test failed.

**Named screenshots:** Use `takeScreenshot: name` in flows to capture key states. These appear inline in the terminal output path.

---

## 11. Write Your Own Flow

Create a new YAML file in `flows/android/` or `flows/ios/`.

**Minimal template:**

```yaml
appId: com.yourcompany.yourapp     # MUST be hardcoded — env vars do not work here
name: "TC-XXX: What this test does"
tags:
  - android
  - smoke
env:
  EMAIL: ${EMAIL}
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
| `launchApp` | Open the app |
| `launchApp: clearState: true` | Restart the app with fresh state |
| `tapOn: "Text"` | Tap by visible text |
| `tapOn: id: "resource_id"` | Tap by resource/accessibility ID *(most reliable)* |
| `tapOn: point: "50%, 34%"` | Tap by screen percentage coordinates |
| `inputText: "hello"` | Type text into focused field |
| `eraseText: 100` | Erase up to 100 characters from focused field |
| `hideKeyboard` | Dismiss the on-screen keyboard |
| `extendedWaitUntil: visible: text: "..." timeout: N` | Wait up to N ms for element |
| `assertVisible: "Text"` | Fail immediately if element is not on screen |
| `assertNotVisible: "Text"` | Fail if element is visible |
| `scroll` | Scroll down |
| `swipe: direction: LEFT` | Swipe left |
| `back` | Press back button (Android) |
| `waitForAnimationToEnd` | Wait for transitions to finish |
| `takeScreenshot: name` | Save a named screenshot |
| `runFlow: file: ../other.yaml` | Execute another flow as a step |

**Using environment variables:**

```yaml
env:
  EMAIL: ${EMAIL}        # declares that this flow needs the EMAIL variable
---
- inputText: ${EMAIL}    # use it in steps like this
```

**Important: `appId:` does NOT support env vars.** Always hardcode the app ID:

```yaml
# WRONG — Maestro will not substitute this
appId: ${ANDROID_APP_ID}

# CORRECT
appId: com.saucelabs.mydemoapp.android
```

**Use `extendedWaitUntil` instead of `assertVisible` with timeout:**

```yaml
# WRONG — timeout is not supported on assertVisible
- assertVisible:
    text: "Products"
    timeout: 5000

# CORRECT
- extendedWaitUntil:
    visible:
      text: "Products"
    timeout: 5000
```

**Use `eraseText: N` instead of `clearText`:**

```yaml
# WRONG — clearText was removed in Maestro 2.x
- clearText

# CORRECT
- eraseText: 100
```

**Finding element IDs (resource IDs):**

Use `adb` to dump the UI hierarchy and find stable IDs:

```powershell
adb shell uiautomator dump /sdcard/ui_dump.xml
adb pull /sdcard/ui_dump.xml ui_dump.xml
# Open ui_dump.xml and search for resource-id attributes
```

Or use Maestro Studio for a live interactive view:

```powershell
maestro studio
```

---

## 12. Troubleshooting

**`maestro: command not found`**  
→ Maestro is not on PATH. Run: `$env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"`

**`adb devices` shows nothing**  
→ Enable USB Debugging on your phone. Try a different USB cable (data cable, not charge-only).

**`INSTALL_FAILED_VERSION_DOWNGRADE`**  
→ Uninstall the existing app first: `adb uninstall com.yourapp.id`

**Flow fails immediately with "App not found" or launches wrong app**  
→ `appId:` in flow files cannot use env vars. Hardcode the package/bundle ID directly.

**`Unknown Property: timeout` in assertVisible**  
→ Replace `assertVisible: text: "..." timeout: N` with `extendedWaitUntil: visible: text: "..." timeout: N`.

**`Invalid Command: clearText`**  
→ `clearText` was removed. Use `eraseText: 100` instead.

**`TypeError: Cannot read property '...' of undefined`**  
→ This usually means a `${VAR:-default.with.dots}` default value was used. Maestro evaluates defaults as JavaScript — dots in the default cause property chain errors. Remove the `:-default` and pass values via `--env` instead.

**Element not found / tap fails even though element is visible**  
→ Use resource IDs (`tapOn: id: "nameET"`) instead of text or coordinates. To find IDs:
```powershell
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml
```

**Coordinate taps hit the wrong element**  
→ The safe coordinate reference for SauceDemo Android (1080×2400 screen):
- Username field: `50%, 34%`
- Password field: `50%, 46%`
- Login button: `50%, 59%`
- Hamburger menu: `7%, 8%`

**Tapping the credential shortcut auto-fills both username and password**  
→ That is intentional — `tapOn: "bod@example.com"` in `perform_login.yaml` uses this shortcut to fill both fields at once. For validation tests that need only one field filled, tap the field directly using its resource ID instead.

**Flow passes locally but fails in CI**  
→ Ensure the emulator is fully booted before running Maestro. Add a boot-wait step in your CI script.

---

## Quick Reference

```powershell
# Add Maestro to PATH (current session)
$env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"

# Install Android APK
adb install -r builds\android\mda-2.2.0-25.apk

# Run one flow
maestro test flows/android/TC-AND-001_login_valid.yaml `
    --env "EMAIL=bod@example.com" --env "PASSWORD=10203040"

# Run all Android tests
maestro test flows/android `
    --env "EMAIL=bod@example.com" --env "PASSWORD=10203040"

# Inspect your app live (find element IDs)
maestro studio

# Dump UI hierarchy for element inspection
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml
```
# maestro_automation
