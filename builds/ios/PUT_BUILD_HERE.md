# iOS Builds

Place your iOS build file in this folder.

## Two types of iOS builds

| File type | Used for | Who provides it |
|-----------|----------|----------------|
| `.app` (folder) | iOS **Simulator** | Developer / Xcode build |
| `.ipa` (file) | iOS **Real device** | Developer / CI / TestFlight |

---

## Simulator build (.app)

### How to get it from Xcode
1. Open your iOS project in Xcode
2. Select an iPhone Simulator as the target device (top toolbar)
3. Press **⌘B** to build
4. Find the output:
   ```
   ~/Library/Developer/Xcode/DerivedData/<YourApp>/Build/Products/Debug-iphonesimulator/YourApp.app
   ```
5. Copy the entire `YourApp.app` folder here

### Install to simulator

```bash
# Boot a simulator first (or use Simulator.app)
xcrun simctl boot "iPhone 15 Pro"

# Install
xcrun simctl install booted builds/ios/YourApp.app
```

---

## Real device build (.ipa)

### How to get it from Xcode
1. Connect your iPhone via USB
2. **Product → Archive**
3. In the Organizer window: **Distribute App → Ad Hoc** (or Development)
4. Save the `.ipa` file here

### Install to real device

```bash
# Install ios-deploy once (requires Node.js)
npm install -g ios-deploy

# Install the IPA
ios-deploy --bundle builds/ios/YourApp.ipa
```

---

## Notes

- `.app` folders and `.ipa` files are gitignored — never commit them
- Re-install whenever you get a new build
- For daily automation, simulator builds are faster and easier to reset
- Use `xcrun simctl erase booted` to reset the simulator to a clean state
