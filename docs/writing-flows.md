# Writing Maestro Flows

A practical guide to writing reliable test flows from scratch.

---

## Flow File Anatomy

Every flow file has two sections separated by `---`:

```yaml
# ── Section 1: Config ──────────────────────────────────
appId: com.yourcompany.yourapp   # MUST be hardcoded — env vars NOT supported here
name: "TC-XXX: What this test does"
tags:
  - android
  - smoke
env:
  EMAIL: ${EMAIL}          # declare vars this flow needs (no :-defaults with dots)
  PASSWORD: ${PASSWORD}
onFlowStart:
  - takeScreenshot: TC-XXX_start
onFlowComplete:
  - takeScreenshot: TC-XXX_complete

# ── Section 2: Steps ───────────────────────────────────
---
- launchApp:
    clearState: true
- tapOn: "Login"
- extendedWaitUntil:
    visible:
      text: "Home"
    timeout: 8000
```

> **Critical:** `appId:` does NOT substitute environment variables. Always hardcode it:
> ```yaml
> # WRONG
> appId: ${ANDROID_APP_ID}
> # CORRECT
> appId: com.saucelabs.mydemoapp.android
> ```

> **Critical:** Do NOT use default values with dots in env vars (`${VAR:-com.example.app}`).  
> Maestro evaluates defaults as JavaScript — dots cause property-chain errors like  
> `TypeError: Cannot read property 'example' of undefined`.  
> Pass all values via `--env` flags instead.

---

## Selector Priority (Most to Least Reliable)

Always prefer selectors in this order:

```yaml
# 1. Resource / Accessibility ID — most stable, doesn't break with UI changes
- tapOn:
    id: "loginBtn"          # matches resource-id="...id/loginBtn"

# 2. Text — works but breaks if wording changes
- tapOn: "Sign In"

# 3. Coordinates — last resort; always breaks when layout changes
- tapOn:
    point: "50%, 34%"

# 4. Index — very fragile, avoid unless necessary
- tapOn:
    text: "Username"
    index: 0
```

**How to find resource IDs** — dump the UI hierarchy from a running emulator:

```powershell
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml
# Open ui.xml and search for resource-id attributes, e.g.:
# resource-id="com.saucelabs.mydemoapp.android:id/loginBtn"
# Use just the short name: id: "loginBtn"
```

Or use Maestro Studio for a live interactive view:

```powershell
maestro studio
```

Ask your developer to add **accessibility labels** to key UI elements. It makes tests far more reliable.

---

## Handling Elements That May or May Not Appear

Use `optional: true` so the flow doesn't fail if the element is absent:

```yaml
- tapOn:
    text: "Allow Notifications"
    optional: true
```

---

## Waiting for the UI

Never use fixed `sleep` delays. Use these instead:

```yaml
# Wait for all animations / transitions to finish
- waitForAnimationToEnd

# Wait up to 8 seconds for an element to appear (use this instead of assertVisible + timeout)
- extendedWaitUntil:
    visible:
      text: "Home"
    timeout: 8000

# Assert immediately (no waiting) — use for elements that should already be visible
- assertVisible: "Home"
```

> **Important:** `assertVisible` does NOT support `timeout:` in Maestro 2.x.  
> Use `extendedWaitUntil` when the element may take time to appear.
> ```yaml
> # WRONG — "Unknown Property: timeout"
> - assertVisible:
>     text: "Products"
>     timeout: 5000
>
> # CORRECT
> - extendedWaitUntil:
>     visible:
>       text: "Products"
>     timeout: 5000
> ```

---

## Reusing Steps with `runFlow`

Break repeated steps (like login) into a subflow and call it:

```yaml
# In TC-AND-002.yaml
---
- runFlow:
    file: ../subflows/navigate_to_login.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android

- runFlow:
    file: ../subflows/perform_login.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
      EMAIL: ${EMAIL}
      PASSWORD: ${PASSWORD}
```

> **Important:** Subflows also require an `appId:` config header. Use `${APP_ID}` in subflows  
> and pass the value via `env:` in each `runFlow:` call.

---

## Scrolling

```yaml
# Scroll down once
- scroll

# Scroll until a specific element is visible
- scrollUntilVisible:
    element:
      text: "Settings"
    direction: DOWN
    timeout: 10000
```

---

## Conditionals (Run Step Only If Element Exists)

```yaml
- runFlow:
    when:
      visible: "Accept Cookies"
    commands:
      - tapOn: "Accept Cookies"
```

---

## Repeat Steps

```yaml
- repeat:
    times: 3
    commands:
      - swipe:
          direction: LEFT
      - waitForAnimationToEnd
```

---

## Text Input

```yaml
# Focus by resource ID (most reliable)
- tapOn:
    id: "nameET"
- inputText: ${EMAIL}
- hideKeyboard           # dismiss keyboard after input

# Erase content before re-typing (eraseText replaces removed clearText)
- tapOn:
    id: "nameET"
- eraseText: 100         # erases up to 100 characters
- inputText: "new value"
- hideKeyboard
```

> **Important:** `clearText` was removed in Maestro 2.x. Use `eraseText: N` (scalar, not map):
> ```yaml
> # WRONG — clearText removed
> - clearText
>
> # WRONG — "Unknown Property: characters"
> - eraseText:
>     characters: 100
>
> # CORRECT
> - eraseText: 100
> ```

---

## Taking Screenshots

```yaml
# In flow config (runs automatically):
onFlowStart:
  - takeScreenshot: TC-001_start
onFlowComplete:
  - takeScreenshot: TC-001_complete

# Inline during steps (useful at key checkpoints):
- takeScreenshot: after_login
```

Debug screenshots on failure are automatically saved to:
```
C:\Users\<name>\.maestro\tests\<timestamp>\
```

---

## Environment Variables

Define in `.env`, declare in flow `env:` section, use in steps:

```env
# .env
ANDROID_EMAIL=bod@example.com
IOS_EMAIL=bob@example.com
PASSWORD=10203040
```

```yaml
# flow.yaml
env:
  EMAIL: ${EMAIL}      # declares this flow needs EMAIL
---
- inputText: ${EMAIL}  # use it in steps
```

Pass on the command line when running directly:
```powershell
maestro test flows/android/TC-AND-001.yaml --env "ANDROID_EMAIL=bod@example.com
IOS_EMAIL=bob@example.com" --env "PASSWORD=10203040"
```

---

## Tags and Test Suites

Tag your flows and run them by group:

```yaml
tags:
  - android
  - smoke        # fast, critical paths
  - auth         # authentication flows
  - validation   # form validation tests
```

```powershell
# Run only smoke tests
.\scripts\run_suite.ps1 -Suite smoke -Platform android
```

---

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Flow files | `TC-<PLATFORM>-<NNN>_description.yaml` | `TC-AND-001_login_valid.yaml` |
| Screenshot names | `TC-XXX_checkpoint` | `TC-AND-001_start` |
| Tags | lowercase, single word | `smoke`, `auth`, `validation` |
| Subflows folder | `subflows/` | `flows/subflows/` |

---

## Checklist: Before Committing a New Flow

- [ ] `appId:` is hardcoded (not an env var)
- [ ] `name:` and `tags:` are set
- [ ] Uses `id:` selectors where possible (dump UI hierarchy to find them)
- [ ] Uses `eraseText: N` — not `clearText` — before re-typing
- [ ] Uses `extendedWaitUntil:` for elements that take time to appear
- [ ] `waitForAnimationToEnd` after navigation actions
- [ ] `onFlowStart` and `onFlowComplete` take screenshots
- [ ] Credentials use `${ENV_VAR}`, not hardcoded values
- [ ] Tested on a real device or emulator before committing
