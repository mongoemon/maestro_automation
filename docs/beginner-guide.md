# Beginner Guide: From Basic Script to Full Structure

This guide teaches you how to write a Maestro test from scratch.  
You'll start with the simplest possible script, understand each piece, and then see how the same test evolves into the structured pattern this project uses.

---

## Part 1 — The Simplest Possible Test

A Maestro flow is just a YAML file with a list of steps. Here is the smallest working test — it opens the app and taps the Login button:

```yaml
appId: com.saucelabs.mydemoapp.android
---
- launchApp
- tapOn: "Login"
```

That's it. Two lines of steps. Let's break down what each part means:

| Line | What it does |
|------|-------------|
| `appId:` | Tells Maestro which app to control. Must be the exact package name. |
| `---` | Separates configuration (above) from steps (below). Always required. |
| `- launchApp` | Opens the app. |
| `- tapOn: "Login"` | Finds an element with text "Login" and taps it. |

Run it:

```bash
maestro test my_test.yaml
```

---

## Part 2 — A Complete Login Test (Inline Style)

Now let's write a real test: open the app, navigate to login, enter credentials, and verify the products screen appears.

Everything is written inline — no separate files, no shared code.

```yaml
appId: com.saucelabs.mydemoapp.android
name: "Login with valid credentials"
tags:
  - smoke
env:
  ANDROID_EMAIL: ${ANDROID_EMAIL}
  PASSWORD: ${PASSWORD}
onFlowStart:
  - takeScreenshot: test_start
onFlowComplete:
  - takeScreenshot: test_complete
---
# 1. Start fresh — clear any saved session from a previous run
- launchApp:
    clearState: true

# 2. Dismiss any system dialogs (Allow / OK / Continue)
- tapOn:
    text: "Allow"
    optional: true
- tapOn:
    text: "OK"
    optional: true
- waitForAnimationToEnd

# 3. Navigate to the login screen
- tapOn:
    point: "7%, 8%"        # tap the hamburger menu icon
- waitForAnimationToEnd
- tapOn: "Log In"
- waitForAnimationToEnd

# 4. Fill in credentials using the shortcut link
- tapOn: ${ANDROID_EMAIL}  # taps "bod@example.com" link — fills both fields
- tapOn: "Login"
- waitForAnimationToEnd

# 5. Assert: the Products screen appeared
- extendedWaitUntil:
    visible:
      text: "Sauce Labs Backpack"
    timeout: 15000
```

### What each new piece does

**Configuration block (before `---`)**

| Key | Purpose |
|-----|---------|
| `name:` | Human-readable label shown in test reports |
| `tags:` | Group tests so you can run subsets (`--include-tags smoke`) |
| `env:` | Declares which variables this test needs. Values come from `--env` flags or `.env` file |
| `onFlowStart:` | Runs before the first step — good for a "before" screenshot |
| `onFlowComplete:` | Runs after the last step (pass or fail) — captures the final screen |

**Steps**

| Step | Why |
|------|-----|
| `clearState: true` | Each test should start from a clean slate so tests don't affect each other |
| `optional: true` | The dialog may or may not appear — don't fail if it's missing |
| `waitForAnimationToEnd` | Waits for the UI to settle before the next step |
| `extendedWaitUntil:` | Polls until the element appears or the timeout expires. Use this instead of `assertVisible` when the element takes time to load |

Run it with credentials:

```bash
maestro test my_test.yaml \
  --env ANDROID_EMAIL=bod@example.com \
  --env PASSWORD=10203040
```

---

## Part 3 — The Problem with Copy-Paste

The inline test above works fine for one test. But now imagine you need five tests:

1. Login with valid credentials
2. Products list appears after login
3. Error when username is empty
4. Error when password is empty
5. Logout returns to login screen

Tests 1, 2, and 5 all need to **navigate to the login screen** first. If you copy-paste those steps into each file, you get this problem:

```
TC-001  opens hamburger → taps "Log In"
TC-002  opens hamburger → taps "Log In"   ← exact copy
TC-005  opens hamburger → taps "Log In"   ← exact copy
```

Now the developer renames "Log In" to "Sign In" in the app. You have to update three files. With ten tests, ten files. With a hundred tests — you spend your whole day updating copy-pasted steps instead of writing new tests.

The solution is **subflows**.

---

## Part 4 — Extract Repeated Steps into a Subflow

A subflow is just another YAML file with steps. The difference: instead of having an `appId` hardcoded to a real value, it uses a variable (`${APP_ID}`) so the caller can pass it in.

**`flows/subflows/login/navigate.yaml`**

```yaml
appId: ${APP_ID}
---
# Open hamburger drawer and go to the login screen
- tapOn:
    point: "7%, 8%"
- waitForAnimationToEnd
- tapOn: "Log In"
- waitForAnimationToEnd
```

**`flows/subflows/login/login.yaml`**

```yaml
appId: ${APP_ID}
---
# Tap credential shortcut (fills both fields on Android), then submit
- tapOn: ${ANDROID_EMAIL}
- tapOn: "Login"
- waitForAnimationToEnd
```

Now the test file calls them instead of repeating the steps:

```yaml
appId: com.saucelabs.mydemoapp.android
name: "Login with valid credentials"
---
- launchApp:
    clearState: true

- runFlow:
    file: ../subflows/login/navigate.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android

- runFlow:
    file: ../subflows/login/login.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
      ANDROID_EMAIL: ${ANDROID_EMAIL}
      PASSWORD: ${PASSWORD}

- extendedWaitUntil:
    visible:
      text: "Sauce Labs Backpack"
    timeout: 15000
```

> **Important:** Every `runFlow:` call must pass all the variables the subflow needs via `env:`.  
> Maestro does not automatically inherit variables from the parent flow.

If "Log In" is renamed tomorrow, you fix it in **one file** — `navigate.yaml` — and all tests that call it update automatically.

---

## Part 5 — The Full Structured Pattern (Page Object Model)

This project takes the subflow idea one step further: each subflow owns exactly one **page** or one **action**. This is called the **Page Object Model (POM)**.

The rule is: *a subflow should only know about one screen. If it touches two screens, split it.*

Here is what the same login test looks like in full POM style — this is exactly how the project's test files are written:

**`flows/android/TC-AND-001_login_valid.yaml`**

```yaml
appId: com.saucelabs.mydemoapp.android
name: "TC-AND-001: Login with valid credentials"
tags:
  - android
  - auth
  - smoke
env:
  ANDROID_EMAIL: ${ANDROID_EMAIL}
  PASSWORD: ${PASSWORD}
onFlowStart:
  - takeScreenshot: TC-AND-001_start
onFlowComplete:
  - takeScreenshot: TC-AND-001_complete
---
- launchApp:
    clearState: true

- runFlow:
    file: ../subflows/login/login.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
      ANDROID_EMAIL: ${ANDROID_EMAIL}
      PASSWORD: ${PASSWORD}

- runFlow:
    file: ../subflows/products/assert_loaded.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
```

The test file is now 30 lines and reads like a plain-English description: *launch, log in, assert products loaded.* All the how is inside the page objects.

### The call chain

When you run `TC-AND-001`, here is what actually happens:

```
TC-AND-001_login_valid.yaml
 │
 ├── subflows/login/login.yaml
 │    └── subflows/login/navigate.yaml
 │         └── subflows/common_actions.yaml  (dismiss system dialogs)
 │
 └── subflows/products/assert_loaded.yaml
```

Each file has one job. If the login screen changes, you only touch `login/navigate.yaml`. If the products screen changes, you only touch `products/assert_loaded.yaml`.

---

## Part 6 — Side-by-Side Comparison

Here is the same login test written three ways:

### Basic (everything inline)

```yaml
appId: com.saucelabs.mydemoapp.android
---
- launchApp:
    clearState: true
- tapOn:
    text: "Allow"
    optional: true
- tapOn:
    text: "OK"
    optional: true
- waitForAnimationToEnd
- tapOn:
    point: "7%, 8%"
- waitForAnimationToEnd
- tapOn: "Log In"
- waitForAnimationToEnd
- tapOn: ${ANDROID_EMAIL}
- tapOn: "Login"
- waitForAnimationToEnd
- extendedWaitUntil:
    visible:
      text: "Sauce Labs Backpack"
    timeout: 15000
```

✅ Simple to understand  
✅ No extra files  
❌ Steps are repeated in every test that needs login  
❌ One change requires editing multiple files

---

### With subflows (extracted repeated steps)

```yaml
appId: com.saucelabs.mydemoapp.android
---
- launchApp:
    clearState: true
- runFlow:
    file: ../subflows/login/navigate.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
- runFlow:
    file: ../subflows/login/login.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
      ANDROID_EMAIL: ${ANDROID_EMAIL}
      PASSWORD: ${PASSWORD}
- extendedWaitUntil:
    visible:
      text: "Sauce Labs Backpack"
    timeout: 15000
```

✅ Login steps are reused — one change fixes all tests  
✅ Test is shorter and easier to read  
❌ Still mixes "navigate and login" and "assert" in the same test body

---

### Full POM (page objects)

```yaml
appId: com.saucelabs.mydemoapp.android
---
- launchApp:
    clearState: true
- runFlow:
    file: ../subflows/login/login.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
      ANDROID_EMAIL: ${ANDROID_EMAIL}
      PASSWORD: ${PASSWORD}
- runFlow:
    file: ../subflows/products/assert_loaded.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
```

✅ Test reads like a spec: launch → login → assert products  
✅ Each subflow has one job  
✅ Adding a new test is fast — just compose existing page objects  
❌ More files to navigate when you're learning the codebase

---

## Part 7 — When to Use Which Approach

| Situation | Recommended approach |
|-----------|---------------------|
| Exploring an app for the first time | Inline — write fast, don't worry about structure |
| A one-off test or spike | Inline — structure isn't worth it for something temporary |
| Writing test 2 or 3 that shares steps with test 1 | Extract into a subflow |
| Building a test suite (5+ tests) | Page Object Model |
| The same interaction appears in 3+ tests | Always extract it into a page object |

A good rule of thumb: **start inline, extract when you find yourself copying**.

---

## Part 8 — Quick Reference: Common Beginner Mistakes

**1. Hardcode the `appId:` — never use a variable**

```yaml
# WRONG — Maestro does not substitute env vars in appId
appId: ${ANDROID_APP_ID}

# CORRECT
appId: com.saucelabs.mydemoapp.android
```

**2. Use `extendedWaitUntil` when elements take time to appear**

```yaml
# WRONG — assertVisible has no timeout in Maestro 2.x
- assertVisible:
    text: "Products"
    timeout: 5000

# CORRECT
- extendedWaitUntil:
    visible:
      text: "Products"
    timeout: 5000
```

**3. Use `eraseText`, not `clearText`**

```yaml
# WRONG — clearText was removed in Maestro 2.x
- clearText

# CORRECT
- eraseText: 100
```

**4. Pass variables to every `runFlow` call**

```yaml
# WRONG — subflow won't see EMAIL
- runFlow:
    file: ./subflows/login/login.yaml

# CORRECT
- runFlow:
    file: ./subflows/login/login.yaml
    env:
      APP_ID: com.saucelabs.mydemoapp.android
      ANDROID_EMAIL: ${ANDROID_EMAIL}
      PASSWORD: ${PASSWORD}
```

**5. Start each test with `clearState: true`**

```yaml
# WRONG — state from the previous run leaks in
- launchApp

# CORRECT
- launchApp:
    clearState: true
```

---

## What to Read Next

- [writing-flows.md](writing-flows.md) — full command reference and selector guide
- [maestro-reference.md](maestro-reference.md) — every Maestro YAML command with examples
- [project-structure.md](project-structure.md) — how this project's files are organized
