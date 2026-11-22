# BrightSprout for iPhone (with real app blocking)

This folder turns BrightSprout into a real iPhone app. It runs the **same** BrightSprout you already have (every feature, from the same `index.html` as the website) and adds real Screen Time blocking:

- A parent picks which apps, app categories and websites to block on the child's iPhone.
- When the child's daily screen time runs out, those apps lock with a BrightSprout screen: "Screen time is done for today".
- The child can tap **Ask a parent for more time** on that screen. The request shows up in Parent > Approve.
- Extra minutes from "+15 / +30 min", approved time requests, rewards like "30 extra minutes of screen time" and Star goals unlock the apps right away.
- BrightSprout itself never locks, so the child can always keep earning Stars.
- Parent mode is protected by a 4-digit parent PIN that is stored in the iPhone's Keychain.

The website on GitHub Pages works exactly as before. All the new code only switches on inside the iPhone app.

## What you need

1. **A Mac** with **Xcode** (free from the Mac App Store). Apple requires a Mac to build iPhone apps.
2. **An Apple Developer account** ($99 a year) at https://developer.apple.com/programs/. A free account can't use Screen Time features.
3. **Family Sharing**, with the child in your family group (Settings > your name > Family). Not needed if you only test on your own iPhone.
4. For the App Store only (not needed for testing): ask Apple for the **Family Controls (Distribution)** permission at https://developer.apple.com/contact/request/family-controls-distribution. You need it once for the app and each of its 3 extensions. Approval can take a few weeks.

## Run it on an iPhone

1. On the Mac, open the Terminal app and run:
   ```
   git clone https://github.com/mishrasanjayk/brightsprout.git
   cd brightsprout/ios
   brew install xcodegen      # needs Homebrew: https://brew.sh
   xcodegen
   open BrightSprout.xcodeproj
   ```
2. In `ios/project.yml`, change `BUNDLE_PREFIX: com.yourname` to something unique, like `com.smithfamily`, and run `xcodegen` again.
3. In Xcode, click the blue **BrightSprout** project at the top left. For **each** of the 4 targets (BrightSprout, BrightSproutMonitor, BrightSproutShield, BrightSproutShieldAction), open **Signing & Capabilities** and choose your **Team**. Xcode sets up the App Group and Family Controls permission for you.
4. Plug in the iPhone, choose it at the top of Xcode, and press the ▶ Run button. The first time, on the iPhone go to Settings > General > VPN & Device Management and trust your developer account. You may also need to turn on Developer Mode (Settings > Privacy & Security).
5. Open BrightSprout on the iPhone, tap **Parent**, create a parent PIN, go to **Settings > Screen time link** and turn it on.
6. In **Real blocking on this iPhone**:
   - Tap **This is my child's iPhone** (a parent signs in with their Apple ID to approve), or **Test on my own iPhone**.
   - Pick **Who uses this iPhone?**
   - Tap **Choose apps** and pick apps or categories (for example Games and Social).
7. To try it quickly, set that child's daily limit to 15 minutes, use a blocked app for 15 minutes, and it locks.

## How the pieces fit

| Folder | What it does |
| --- | --- |
| `App/` | The app: shows BrightSprout, the app picker and the parent PIN, and passes settings between BrightSprout and Screen Time. |
| `Monitor/` | Runs in the background, even when BrightSprout is closed. Locks apps when time runs out and unlocks them at midnight. |
| `ShieldConfig/` | The "Screen time is done for today" screen shown on locked apps. |
| `ShieldAction/` | The "Ask a parent for more time" button on that screen. |
| `Shared/` | Settings and blocking logic used by all of the above. |
| `../index.html` | The BrightSprout web app, bundled into the app so it works offline. |

## Not tested yet

This code was written without a Mac, so it has **not been built or run on an iPhone**. Expect a few small Xcode fixes on the first build. Things to check:

- Real blocking and unblocking on a device (Apple's Screen Time features don't work in the iPhone Simulator).
- Kids' progress being saved between launches, and YouTube videos playing inside the app.
- On iOS older than 17.4, extra minutes count from when a parent gives them, so they can be a little generous.

## Known limits for now

- Everything happens on the child's iPhone, so a parent grants more time on that phone with the PIN. Granting time from the parent's own phone needs a sync service (for example iCloud/CloudKit), which is a good next step.
- Sprout AI only works inside Claude, as it does on the website.
- Exact minutes used aren't shown yet. That needs one more extension (a Screen Time report).
