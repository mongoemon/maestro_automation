# Project Structure

A detailed map of every directory and file in this repository, including how they relate to each other.

---

## Directory Tree

```
maestro_automation/
│
├── app/                            ← App binaries (gitignored, download with script)
│   ├── android/
│   │   └── mda-2.2.0-25.apk
│   └── ios/
│       ├── SauceLabs-Demo-App.Simulator.zip
│       └── Payload/
│           └── My Demo App.app     ← extracted from the zip
│
├── flows/                          ← All Maestro test flows
│   ├── android/                    ← Android test cases
│   │   ├── TC-AND-001_login_valid.yaml
│   │   ├── TC-AND-002_products_after_login.yaml
│   │   ├── TC-AND-003_login_error_empty_username.yaml
│   │   ├── TC-AND-004_login_error_empty_password.yaml
│   │   └── TC-AND-005_logout.yaml
│   │
│   ├── ios/                        ← iOS test cases (mirror of Android)
│   │   ├── TC-IOS-001_login_valid.yaml
│   │   ├── TC-IOS-002_products_after_login.yaml
│   │   ├── TC-IOS-003_login_error_empty_username.yaml
│   │   ├── TC-IOS-004_login_error_empty_password.yaml
│   │   ├── TC-IOS-005_logout.yaml
│   │   └── subflows/               ← iOS-specific helpers
│   │       ├── navigate_to_login.yaml
│   │       └── perform_login.yaml
│   │
│   └── subflows/                   ← Shared helpers (used by Android flows)
│       ├── common_actions.yaml
│       ├── navigate_to_login.yaml
│       └── perform_login.yaml
│
├── scripts/
│   ├── download_apps.py            ← Download APK / IPA from GitHub Releases
│   ├── apps.yaml                   ← Your download config (gitignored)
│   ├── apps.yaml.example           ← Template — copy to apps.yaml
│   ├── run_all.ps1                 ← Run all flows for a platform
│   ├── run_suite.ps1               ← Run a named tag group (smoke, auth…)
│   └── run_flow.ps1                ← Run one specific flow
│
├── docs/
│   ├── project-structure.md        ← This file
│   ├── android-setup.md            ← Android emulator / device setup
│   ├── ios-setup.md                ← iOS simulator / device setup
│   ├── writing-flows.md            ← Guide for writing new flows
│   └── test-cases.xlsx             ← Test case specification spreadsheet
│
├── reports/                        ← JUnit XML output (gitignored)
│
├── .env                            ← Your credentials (gitignored — never commit)
├── .env.example                    ← Credential template
├── .env copy.example               ← Alternate template copy
├── requirements.txt                ← Python dependency (junit2html)
└── .gitignore
```

---

## flows/

### Test case naming

Every flow file follows the pattern:

```
TC-<PLATFORM>-<NUMBER>_<short_description>.yaml
```

| Part | Example | Meaning |
|------|---------|---------|
| `TC` | `TC` | Test Case |
| Platform | `AND` / `IOS` | Android or iOS |
| Number | `001` | Zero-padded sequence |
| Description | `login_valid` | Slug summarising what is tested |

The same scenario number maps across platforms: `TC-AND-001` and `TC-IOS-001` test the same feature on different platforms.

### Flow file anatomy

Every flow file has two sections separated by `---`:

```yaml
# ── Header (Maestro metadata) ─────────────────────────────────
appId: com.saucelabs.mydemoapp.android   # hardcoded — env vars not supported here
name: "TC-AND-001: Login with valid credentials"
tags:
  - android
  - smoke
env:
  ANDROID_EMAIL: ${ANDROID_EMAIL}        # declare variables the flow needs
  PASSWORD: ${PASSWORD}
onFlowStart:
  - takeScreenshot: TC-AND-001_start     # captured before any steps run
onFlowComplete:
  - takeScreenshot: TC-AND-001_complete  # captured after the last step (pass or fail)
---
# ── Body (test steps) ─────────────────────────────────────────
- launchApp:
    clearState: true
- ...
```

### Subflow architecture

Flows call reusable subflows via `runFlow:`. This keeps the login sequence in one place and avoids copy-paste.

**Android call chain:**

```
TC-AND-001_login_valid.yaml
 └── flows/subflows/navigate_to_login.yaml
 │    └── flows/subflows/common_actions.yaml   (dismiss system dialogs)
 └── flows/subflows/perform_login.yaml
```

**iOS call chain:**

```
TC-IOS-001_login_valid.yaml
 └── flows/ios/subflows/navigate_to_login.yaml
 │    └── flows/subflows/common_actions.yaml   (shared — dismiss system dialogs)
 └── flows/ios/subflows/perform_login.yaml
```

iOS has its own `navigate_to_login.yaml` and `perform_login.yaml` in `flows/ios/subflows/` because the login UI interaction differs between platforms (iOS uses a tab bar to reach Login; Android uses a hamburger drawer). `common_actions.yaml` is shared because dismissing system permission dialogs is the same on both.

### Subflow responsibilities

| File | Purpose |
|------|---------|
| `common_actions.yaml` | Taps Allow / OK / Continue to dismiss any system dialog that appears on app launch |
| `navigate_to_login.yaml` (shared) | Opens the hamburger drawer and taps "Log In" (Android). Also dismisses the App Compatibility dialog that appears on the login screen |
| `navigate_to_login.yaml` (ios) | Taps the "More" tab then "Login Button" to reach the login screen (iOS) |
| `perform_login.yaml` (shared) | Taps the credential shortcut link to auto-fill both username and password, then taps Login (Android). Also dismisses the App Compatibility dialog after navigating to the products screen |
| `perform_login.yaml` (ios) | Taps the credential shortcut to fill the username field, then taps the password field and types the password manually (iOS shortcuts fill username only) |

### Tags

Tags group flows into named suites runnable with `run_suite.ps1`:

| Tag | Applied to |
|-----|-----------|
| `smoke` | TC-001, TC-002, TC-005 — fast, critical-path checks |
| `auth` | TC-001 through TC-005 — all auth-related flows |
| `validation` | TC-003, TC-004 — error message / form validation |

---

## scripts/

### download_apps.py

Downloads the APK and/or IPA from the URL configured in `scripts/apps.yaml`. Reads the `source` field to decide whether to use the public `saucelabs_url` or a private `private_url` (requires `GITHUB_TOKEN`).

```bash
python scripts/download_apps.py              # both platforms
python scripts/download_apps.py --android    # Android only
python scripts/download_apps.py --ios        # iOS only
python scripts/download_apps.py --force      # re-download even if file exists
```

### apps.yaml

Controls what gets downloaded. Copy `apps.yaml.example` to `apps.yaml` and edit:

```yaml
source: saucelabs        # "saucelabs" uses the public URL; "private" uses private_url

android:
  filename: mda-2.2.0-25.apk
  saucelabs_url: "https://github.com/saucelabs/my-demo-app-android/releases/..."
  private_url: ""        # fill in for private hosting

ios:
  filename: SauceLabs-Demo-App.Simulator.zip
  saucelabs_url: "https://github.com/saucelabs/my-demo-app-ios/releases/..."
  private_url: ""
```

`apps.yaml` is gitignored so team members can point to different sources without affecting each other.

### PowerShell scripts

All three scripts read credentials from `.env` automatically.

| Script | Usage |
|--------|-------|
| `run_flow.ps1` | `.\scripts\run_flow.ps1 -Flow flows/android/TC-AND-001_login_valid.yaml -Platform android` |
| `run_all.ps1` | `.\scripts\run_all.ps1 -Platform ios` — runs every flow in the platform folder |
| `run_suite.ps1` | `.\scripts\run_suite.ps1 -Platform android -Suite smoke` — filters by tag |

Pass `-Report` to `run_all.ps1` or `run_suite.ps1` to generate a JUnit XML file in `reports/`.

---

## Environment variables

Credentials are passed to flows via `--env` flags. The `.env` file is loaded automatically by the PowerShell scripts; when running `maestro` directly, pass them on the command line.

| Variable | Used by | Value |
|----------|---------|-------|
| `ANDROID_EMAIL` | Android flows | `bod@example.com` |
| `IOS_EMAIL` | iOS flows | `bob@example.com` |
| `PASSWORD` | Both platforms | `10203040` |
| `ANDROID_APP_ID` | Scripts only | `com.saucelabs.mydemoapp.android` |
| `IOS_APP_ID` | Scripts only | `com.saucelabs.mydemo.app.ios` |

> Android and iOS use **different** credential shortcut values in the demo app — this is why they have separate email variables.

The `APP_ID` variables are used by the helper scripts to set the `APP_ID` env var passed to subflows. They are **not** used inside the `appId:` flow header (Maestro does not substitute env vars there).

---

## .gitignore highlights

| Ignored path | Reason |
|-------------|--------|
| `.env` | Contains credentials |
| `app/android/*.apk`, `app/ios/*.app` etc. | Binary artifacts — download with script |
| `reports/` | Generated output |
| `/*.png` | Debug screenshots captured in the root during exploratory runs |
| `results.xml`, `report.html` | Generated test output |
| `.claude/settings.local.json` | Personal Claude Code overrides |
| `scripts/apps.yaml` | Per-developer download config |
