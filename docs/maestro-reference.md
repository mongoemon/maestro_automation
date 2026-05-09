# Maestro Reference Guide

Practical reference for the Maestro CLI and YAML flow commands, plus a troubleshooting index.  
For project-specific setup see [android-setup.md](android-setup.md) or [ios-setup.md](ios-setup.md).  
For writing patterns see [writing-flows.md](writing-flows.md).

---

## Table of Contents

1. [CLI Commands](#1-cli-commands)
2. [App Lifecycle](#2-app-lifecycle)
3. [Tapping & Gestures](#3-tapping--gestures)
4. [Text Input](#4-text-input)
5. [Scrolling & Swiping](#5-scrolling--swiping)
6. [Assertions & Waiting](#6-assertions--waiting)
7. [Flow Control](#7-flow-control)
8. [Screenshots & Debugging](#8-screenshots--debugging)
9. [Environment Variables](#9-environment-variables)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. CLI Commands

### Run a single flow

```bash
maestro test flows/android/TC-AND-001_login_valid.yaml \
    --env ANDROID_EMAIL=bod@example.com \
    --env PASSWORD=10203040
```

### Run all flows in a folder

```bash
maestro test flows/android/
maestro test flows/ios/
```

### Filter by tag

```bash
# Only run flows tagged "smoke"
maestro test flows/android/ --include-tags smoke

# Exclude a tag
maestro test flows/android/ --exclude-tags flaky

# Multiple tags (runs flows that have ANY of the listed tags)
maestro test flows/android/ --include-tags smoke,auth
```

### Generate a JUnit XML report

```bash
maestro test flows/android/ \
    --env ANDROID_EMAIL=bod@example.com \
    --env PASSWORD=10203040 \
    --format junit \
    --output results.xml
```

Convert to HTML (requires `pip install junit2html`):

```bash
junit2html results.xml report.html
```

### Open the live element inspector (Maestro Studio)

```bash
maestro studio
```

Studio opens a browser window. Connect a device/emulator first. Use it to:
- See the full accessibility/UI hierarchy
- Find element IDs and text values
- Record taps interactively

### Check version

```bash
maestro --version
# Maestro v2.5.1
```

### Pass multiple `--env` values

```bash
# One flag per variable
maestro test flow.yaml \
    --env ANDROID_EMAIL=bod@example.com \
    --env PASSWORD=10203040 \
    --env APP_ENV=staging
```

---

## 2. App Lifecycle

### Launch the app

```yaml
# Simple launch (does not clear state)
- launchApp

# Launch with a clean slate (recommended for test isolation)
- launchApp:
    clearState: true

# Launch and pass arguments to the app
- launchApp:
    arguments:
      - "--demo-mode"
```

### Stop the app

```yaml
- stopApp
```

### Clear app data without relaunching

```yaml
- clearAppState
```

### Clear the Keychain / secure storage (iOS only)

```yaml
- clearKeychain
```

---

## 3. Tapping & Gestures

### Tap by visible text

```yaml
- tapOn: "Login"

# With options
- tapOn:
    text: "Login"
    index: 1        # second element matching "Login" (0-based)
    optional: true  # skip if element not found instead of failing
```

### Tap by resource / accessibility ID

```yaml
# Most reliable — doesn't break when text changes
- tapOn:
    id: "loginBtn"
```

> **Android:** `id:` matches the short name part of `resource-id`.  
> Full: `com.saucelabs.mydemoapp.android:id/loginBtn` → use `loginBtn`.  
> **iOS:** `id:` matches the accessibility identifier set by the developer.

### Tap by screen coordinates

```yaml
# Percentage-based (same across all screen sizes)
- tapOn:
    point: "50%, 34%"

# Absolute pixels (fragile — avoid)
- tapOn:
    point: "540, 816"
```

> Use coordinates only as a last resort. They break when screen size or layout changes.

### Long press

```yaml
- longPressOn: "Delete Item"

- longPressOn:
    id: "itemCard"
    duration: 2000    # hold for 2 seconds (default: 500ms)
```

### Double tap

```yaml
- doubleTapOn: "Image"
```

### Tap at a specific point relative to an element

```yaml
- tapOn:
    text: "Map"
    childOf: "section-header"
```

---

## 4. Text Input

### Type into the focused field

```yaml
- tapOn:
    id: "nameET"
- inputText: "hello@example.com"
```

### Type an environment variable

```yaml
- inputText: ${ANDROID_EMAIL}
```

### Erase field content before retyping

```yaml
- tapOn:
    id: "nameET"
- eraseText: 100      # erase up to 100 characters
- inputText: "new value"
```

> `clearText` was removed in Maestro 2.x — always use `eraseText: N`.

### Dismiss the keyboard

```yaml
- hideKeyboard
```

> `hideKeyboard` works reliably on Android. On iOS it may fail if the app uses a custom input view — in that case tap a static, non-interactive text label instead:
> ```yaml
> - tapOn:
>     text: "Select a username from the list below"
> ```

### Press a hardware / keyboard key

```yaml
- pressKey: Enter
- pressKey: Backspace
- pressKey: Back        # Android back button
- pressKey: Home        # Android home button
- pressKey: Lock        # power button (lock screen)
- pressKey: VolumeUp
- pressKey: VolumeDown
```

---

## 5. Scrolling & Swiping

### Scroll down once

```yaml
- scroll
```

### Scroll in a direction

```yaml
- scroll:
    direction: UP     # UP | DOWN | LEFT | RIGHT
    speed: 40         # 1–100, default 40
```

### Scroll until an element is visible

```yaml
- scrollUntilVisible:
    element:
      text: "Terms and Conditions"
    direction: DOWN
    timeout: 15000      # give up after 15 seconds
    speed: 30
```

### Swipe

```yaml
# Swipe from one screen edge to another
- swipe:
    direction: LEFT     # LEFT | RIGHT | UP | DOWN

# Swipe from a specific start point to end point
- swipe:
    startX: 80%
    startY: 50%
    endX: 20%
    endY: 50%
    duration: 400       # milliseconds
```

---

## 6. Assertions & Waiting

### Wait for an element to appear (with timeout)

```yaml
# Preferred — polls until visible or timeout expires
- extendedWaitUntil:
    visible:
      text: "Products"
    timeout: 10000      # milliseconds

# Also works with id
- extendedWaitUntil:
    visible:
      id: "productList"
    timeout: 10000
```

### Assert element is visible right now (no waiting)

```yaml
# Fails immediately if not on screen
- assertVisible: "Welcome"

- assertVisible:
    text: "Welcome"
    optional: true    # warn but don't fail if missing
```

### Assert element is NOT on screen

```yaml
- assertNotVisible: "Error message"
```

### Wait for animations to finish

```yaml
- waitForAnimationToEnd

# With a max wait time
- waitForAnimationToEnd:
    timeout: 5000
```

### Wait for the app to settle (fixed pause — avoid when possible)

```yaml
# Only use this when waitForAnimationToEnd is not enough
- wait:
    ms: 2000
```

---

## 7. Flow Control

### Call another flow as a subflow

```yaml
- runFlow:
    file: ../subflows/navigate_to_login.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
      ANDROID_EMAIL: ${ANDROID_EMAIL}
```

### Run steps conditionally

```yaml
# Run the commands block only if "Accept" is visible
- runFlow:
    when:
      visible: "Accept Cookies"
    commands:
      - tapOn: "Accept Cookies"
      - waitForAnimationToEnd
```

### Repeat steps

```yaml
- repeat:
    times: 5
    commands:
      - swipe:
          direction: LEFT
      - waitForAnimationToEnd
```

### Navigate back (Android)

```yaml
- back
```

---

## 8. Screenshots & Debugging

### Capture a named screenshot inline

```yaml
- takeScreenshot: after_login
```

Files are saved in the directory where `maestro` was run (e.g. the project root).

### Automatic start / complete screenshots (set in flow header)

```yaml
onFlowStart:
  - takeScreenshot: TC-001_start
onFlowComplete:
  - takeScreenshot: TC-001_complete
```

`onFlowComplete` fires on both pass and fail — always captures the final screen state.

### Debug artifacts on failure

Maestro automatically saves a failure screenshot and logs to:

```
# macOS / Linux
~/.maestro/tests/<timestamp>/

# Windows
C:\Users\<name>\.maestro\tests\<timestamp>\
```

The folder contains:
| File | Contents |
|------|---------|
| `screenshot-❌-<ts>-(<flow>).png` | Screen state at the moment of failure |
| `screenshot-⚠️-<ts>-(<flow>).png` | Screen state when an optional step was skipped |
| `maestro.log` | Full step-by-step execution log with timestamps |
| `commands-(<flow>).json` | Machine-readable command trace |

### Inspect the UI hierarchy live

```bash
maestro studio
```

### Dump the Android UI hierarchy to a file

```bash
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml
# Open ui.xml and search for resource-id, text, content-desc attributes
```

---

## 9. Environment Variables

### Declare and use in a flow

```yaml
# Header — declare all vars the flow needs
env:
  ANDROID_EMAIL: ${ANDROID_EMAIL}
  PASSWORD: ${PASSWORD}
---
# Body — use them in steps
- tapOn: ${ANDROID_EMAIL}
- inputText: ${PASSWORD}
```

### Pass on the command line

```bash
maestro test flow.yaml \
    --env ANDROID_EMAIL=bod@example.com \
    --env PASSWORD=10203040
```

### Pass via .env file (using helper scripts)

The PowerShell scripts in `scripts/` load `.env` automatically. Copy `.env.example` to `.env` and fill in values — no `--env` flags needed when using `run_flow.ps1` or `run_all.ps1`.

### Important rules

| Rule | Detail |
|------|--------|
| `appId:` cannot use env vars | Always hardcode: `appId: com.example.app` |
| No `:-default` with dots | `${VAR:-com.example}` crashes — dots are parsed as JS property access |
| Subflows need vars forwarded | Pass `env:` in every `runFlow:` call that needs them |

---

## 10. Troubleshooting

### CLI / Setup

---

**`maestro: command not found`**

Maestro is not on your PATH.

```bash
# macOS/Linux — add to ~/.zshrc or ~/.bashrc
export PATH="$PATH:$HOME/.maestro/bin"
source ~/.zshrc

# Windows — current session only
$env:PATH = "$env:PATH;$env:USERPROFILE\maestro\bin"
```

---

**`java: command not found` or `JAVA_HOME not set`**

Install Java 11+ from https://adoptium.net. On macOS:

```bash
brew install --cask temurin
```

---

**`adb: command not found`**

Add Android SDK `platform-tools` to PATH:

```bash
# macOS — add to ~/.zshrc
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

# Windows
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$sdkPath", "User")
```

---

### Device / Emulator Connection

---

**`No connected devices / emulators found`**

```bash
adb devices    # should list at least one device
```

- Android emulator: make sure it's fully booted (home screen visible)
- Android physical device: enable USB Debugging; try a different cable
- iOS simulator: `xcrun simctl boot "iPhone 16 Pro" && open -a Simulator`

---

**`Command failed (tcp:7001): closed` (Android)**

Maestro can't reach its gRPC driver on the device. Kill the stale process and reset the port:

```bash
pkill -f maestro-d           # kill stale Maestro daemon (macOS/Linux)
adb forward --remove-all
adb forward tcp:7001 tcp:7001
# Then re-run your test
```

---

**`device offline` or `adb` unresponsive**

```bash
adb kill-server
adb start-server
adb devices
```

---

**`INSTALL_FAILED_VERSION_DOWNGRADE`**

Uninstall the existing app first:

```bash
adb uninstall com.saucelabs.mydemoapp.android
adb install -r app/android/mda-2.2.0-25.apk
```

---

**`Unable to find a booted simulator` (iOS)**

```bash
xcrun simctl boot "iPhone 16 Pro"
open -a Simulator
```

List available simulators:

```bash
xcrun simctl list devices available
```

---

### Flow Execution

---

**Flow fails immediately with `App not found` or launches the wrong app**

`appId:` in flow files does not support environment variables. Use the hardcoded package/bundle ID:

```yaml
# WRONG
appId: ${ANDROID_APP_ID}

# CORRECT
appId: com.saucelabs.mydemoapp.android
```

---

**`Element not found: Text matching regex: <value>`**

The element Maestro is looking for doesn't exist on screen at that moment. Steps to diagnose:

1. Open the failure screenshot in `~/.maestro/tests/<timestamp>/` to see what was on screen.
2. Run `maestro studio` to inspect the live hierarchy and find the exact text/ID.
3. Check if the element is behind a dialog or loading spinner — add `waitForAnimationToEnd` before the tap.
4. If the element text changes between app versions, switch to `id:` selector.

---

**`Unknown Property: timeout` on assertVisible**

`assertVisible` does not support `timeout:` in Maestro 2.x. Use `extendedWaitUntil:` instead:

```yaml
# WRONG
- assertVisible:
    text: "Products"
    timeout: 5000

# CORRECT
- extendedWaitUntil:
    visible:
      text: "Products"
    timeout: 5000
```

---

**`Invalid Command: clearText`**

`clearText` was removed in Maestro 2.x:

```yaml
# WRONG
- clearText

# WRONG (also fails — "Unknown Property: characters")
- eraseText:
    characters: 100

# CORRECT
- eraseText: 100
```

---

**`TypeError: Cannot read property '...' of undefined`**

You used a default value with dots, e.g. `${APP_ID:-com.example.app}`. Maestro evaluates defaults as JavaScript — the dot is parsed as property access and crashes. Remove the default and always pass values via `--env`:

```yaml
# WRONG
env:
  APP_ID: ${APP_ID:-com.example.app}

# CORRECT — pass the value with --env APP_ID=com.example.app
env:
  APP_ID: ${APP_ID}
```

---

**Password field stays empty (iOS)**

iOS does not expose a reliable way to focus a password field by coordinate after typing in the username (the keyboard shifts the layout). The pattern that works:

1. Tap the **credential shortcut link** to fill the username field (no keyboard opens).
2. Tap the password field by coordinate — with no keyboard in the way, the layout is stable.

```yaml
- tapOn: "${IOS_EMAIL}"          # fill username via shortcut, no keyboard
- waitForAnimationToEnd
- tapOn:
    point: "50%, 53%"            # password field center
- inputText: ${PASSWORD}
```

---

**`hideKeyboard` fails on iOS with "custom input" error**

Some iOS apps use a non-standard input view that doesn't respond to the system dismiss action. Tap a static, non-interactive text element on screen to resign first responder:

```yaml
# Instead of hideKeyboard:
- tapOn:
    text: "Select a username from the list below"
- waitForAnimationToEnd
```

---

**Android App Compatibility dialog blocks every screen**

Some APKs compiled without 16 KB page alignment show this dialog on Android 15 emulators. It can appear multiple times per session. Dismiss it with an optional tap wherever it may appear:

```yaml
- tapOn:
    text: "OK"
    optional: true
- waitForAnimationToEnd
```

Add this after any navigation step that could trigger the dialog (app launch, screen transition, drawer navigation).

---

**Assertion passes locally but fails in CI**

Common causes:

| Cause | Fix |
|-------|-----|
| Emulator not fully booted | Wait for `sys.boot_completed=1` before running Maestro |
| Slow CI machine needs longer waits | Increase `timeout:` on `extendedWaitUntil:` |
| Missing `--env` flags | Confirm CI passes `ANDROID_EMAIL`, `IOS_EMAIL`, `PASSWORD` |
| Emulator animation speed not disabled | Run `adb shell settings put global window_animation_scale 0` in CI setup |

Boot-wait snippet for CI scripts:

```bash
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do
  sleep 2
done
```

---

**Flow passes on first run but fails on retry**

The app state from the previous run is leaking in. Always start with:

```yaml
- launchApp:
    clearState: true
```

---

**Coordinate taps hit the wrong element**

Percentage coordinates are calculated from the full screen. They can drift if:
- The status bar height differs between device/emulator
- The keyboard is still open, compressing the content area
- The device has a different aspect ratio

Fix: switch to `id:` or `text:` selectors. If you must use coordinates, dismiss the keyboard first and confirm measurements with `maestro studio`.
