# iOS Setup Guide

Complete guide for setting up iOS testing with Maestro. **Requires a Mac.**

---

## 1. Install Xcode

1. Open the **Mac App Store**
2. Search for **Xcode** and install it (large download, ~12 GB)
3. After install, open Xcode once to accept the license and install components

Verify command-line tools are installed:

```bash
xcode-select --install
# If already installed: "xcode-select: error: command line tools are already installed"

xcrun --version
# xcrun version XX
```

---

## 2. Set Up iOS Simulator

List available simulators:

```bash
xcrun simctl list devices available
```

Boot a simulator (pick one from the list above):

```bash
xcrun simctl boot "iPhone 16 Pro"
```

Open the Simulator app to see it:

```bash
open -a Simulator
```

---

## 3a. Install a Simulator Build (.app)

### Get the build

**Option A — Download automatically (recommended):**

```bash
# 1. Install the only dependency
pip install pyyaml

# 2. Copy the example config and fill in URLs (one-time setup)
cp scripts/apps.yaml.example scripts/apps.yaml
# Edit scripts/apps.yaml — set source, filename, and saucelabs_url / private_url

# 3. Download
python scripts/download_apps.py --ios
```

The file lands at `app/ios/<filename>` (gitignored).

For the SauceLabs simulator build, a `.zip` is downloaded — extract it before installing:

```bash
unzip app/ios/SauceLabs-Demo-App.Simulator.zip -d app/ios/
# App bundle lands at: app/ios/Payload/My Demo App.app
```

For private GitHub releases, set your token first:

```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
python scripts/download_apps.py --ios
```

**Option B — Build from Xcode:**
1. Select an **iPhone Simulator** as the run destination (top toolbar)
2. Press **⌘B** to build (no need to run)
3. Find the `.app` at:
   ```
   ~/Library/Developer/Xcode/DerivedData/<AppName>/Build/Products/Debug-iphonesimulator/<AppName>.app
   ```
   Then copy: `cp -r /path/to/YourApp.app app/ios/YourApp.app`

### Install to simulator

```bash
xcrun simctl install booted app/ios/YourApp.app
```

---

## 3b. Install a Real Device Build (.ipa)

### Get the build

**Option A — Download automatically (recommended):**

```bash
python scripts/download_apps.py --ios
# IPA lands at app/ios/<filename>
```

**Option B — Export from Xcode:**
1. **Product → Archive**
2. In the Organizer: **Distribute App → Ad Hoc** (or Development)
3. Export and copy the `.ipa` to `app/ios/YourApp.ipa`

Or get it from your CI pipeline / TestFlight export.

### Install to a real device

```bash
# Install the tool once
npm install -g ios-deploy

# Connect iPhone via USB, then:
ios-deploy --bundle app/ios/YourApp.ipa
```

---

## 4. Find Your App's Bundle Identifier

You need this for `APP_ID` in your `.env` file.

**From Xcode:**
1. Open your project
2. Click the project name in the Navigator
3. Select your app Target → **General** tab
4. Copy the **Bundle Identifier** (e.g. `com.yourcompany.appname`)

**From a .app bundle:**
```bash
/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" builds/ios/YourApp.app/Info.plist
```

---

## 5. Run a Test

```bash
# Make sure simulator is booted and app is installed

# Using the helper script (reads credentials from .env automatically)
pwsh scripts/run_flow.ps1 -Flow flows/ios/TC-IOS-001_login_valid.yaml -Platform ios
# (reads IOS_EMAIL and PASSWORD from .env automatically)

# Or run directly with maestro:
maestro test flows/ios/TC-IOS-001_login_valid.yaml \
    --env IOS_EMAIL=bob@example.com \
    --env PASSWORD=10203040
```

---

## 6. Reset Simulator State (Clean Test Run)

```bash
# Erase all data on the booted simulator (like a factory reset)
xcrun simctl erase booted
```

Use this when a test leaves the app in a dirty state.

---

## Common iOS Issues

| Error | Fix |
|-------|-----|
| `Unable to find a booted simulator` | Run `xcrun simctl boot "iPhone 16"` |
| App not found / wrong bundle ID | Verify with `PlistBuddy` command above |
| `Untrusted Developer` on real device | Settings → General → VPN & Device Management → Trust |
| Tests flaky on simulator | Add `waitForAnimationToEnd` after transitions; increase `timeout` values |
| `ios-deploy` not found | `npm install -g ios-deploy` |
