# KeyLoom - Floating Virtual Keyboard for macOS

![Keyboard](screenshots/final/hero.png)

A native macOS floating keyboard panel that lives above all windows, accessible from the menu bar, works across every app.

## Screenshots

| Keyboard | Clipboard | Quick Keys |
|---|---|---|
| ![Keyboard](screenshots/final/keyboard.png) | ![Clipboard](screenshots/final/clipboard.png) | ![Quick Keys](screenshots/final/quick-keys.png) |

| Layout | Style | Behavior | Clipboard | Sounds |
|---|---|---|---|---|
| ![Layout](screenshots/final/settings-layout.png) | ![Style](screenshots/final/settings-style.png) | ![Behavior](screenshots/final/settings-behavior.png) | ![Clipboard](screenshots/final/settings-clipboard.png) | ![Sounds](screenshots/final/settings-sounds.png) |

## Features

- **Floating virtual keyboard** - sits above all windows, drag anywhere
- **Menu bar icon** (keyboard) - click to show/hide
- **Clipboard history** - auto-monitors clipboard, search, pin favorites, export
- **Quick Keys panel** - compact strip of your most-used keys
- **Broken keys** - highlight frequently used keys in custom colors
- **Physical keyboard sync** - Shift and Caps Lock follow your real keyboard
- **Customizable** - 8 fonts, neomorphism 3D, key sizes, spacing, sounds
- **6 distinct key click sounds** - Key Click, Soft, Mechanical, Glass, Minimal, Bottle
- **Launch at login** - optional auto-start
- **Full QWERTY layout** with Shift, Caps Lock, Tab, Enter, Backspace
- **Works in all spaces** and full-screen apps

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later (to build)
- Accessibility permission (for automatic paste)

## Build & Run

### Xcode (recommended)
1. Open `KeyLoom.xcodeproj` in Xcode
2. Select your Mac as the run destination
3. Press **Cmd+R** to build and run

### Command line
```bash
xcodebuild -project KeyLoom.xcodeproj -scheme KeyLoom -configuration Release build
```

### Run tests
```bash
xcodebuild -project KeyLoom.xcodeproj -scheme KeyLoomTests -configuration Debug test
```

## First-time Setup

On first launch, macOS may ask for **Accessibility permissions** so the app can paste into other apps via Cmd+V simulation. Grant this in:

> System Settings > Privacy & Security > Accessibility > KeyLoom

## Deployment

KeyLoom is distributed **outside the Mac App Store** (sandbox is disabled for clipboard/keystroke access). The distribution path is:

1. Build release: `./scripts/build-release.sh`
2. Notarize: `APPLE_ID="..." APPLE_TEAM_ID="..." AC_PASSWORD="..." ./scripts/notarize.sh`
3. Distribute the DMG or .app via your preferred channel

### Fastlane
```bash
fastlane mac release          # Full release: build -> DMG -> notarize
fastlane mac bump version:1.1.0  # Bump version & tag
```

### CI/CD
GitHub Actions workflows are included for CI (`.github/workflows/ci.yml`) and automated releases (`.github/workflows/release.yml`).

## Architecture

```
KeyLoom.xcodeproj
├── KeyLoom/                        # Main app source
│   ├── KeyLoomApp.swift            # Entry point, menu bar, floating panel, AppDelegate
│   ├── KeyboardView.swift          # Full QWERTY keyboard UI
│   ├── KeyboardState.swift         # Keyboard state (shift, caps, etc.)
│   ├── KeyModel.swift              # Key structs, key layout data
│   ├── KeyButton.swift             # Individual key view with neomorphism
│   ├── CollapsedKeyboardView.swift # Quick-keys minimal panel
│   ├── SettingsView.swift          # Settings panel (5 tabs)
│   ├── KeyboardSettings.swift      # All user preferences
│   ├── ClipboardManager.swift      # Clipboard monitoring, pinning, history
│   ├── ClipboardViews.swift        # Clipboard panel UI
│   ├── SoundManager.swift          # WAV synthesis engine, 6 sound styles
│   ├── KeystrokeSender.swift       # CGEvent-based paste simulation
│   ├── PhysicalShiftMonitor.swift  # Physical Shift/Caps Lock sync
│   ├── KeyUsageTracker.swift       # Broken key frequency tracking
│   ├── WelcomeView.swift           # First-launch guide & help screens
│   ├── Info.plist                  # App metadata
│   ├── KeyLoom.entitlements        # Sandbox & Apple Events entitlements
│   └── Assets.xcassets/            # App icons & accent color
├── KeyLoomTests/                   # Unit tests
│   └── KeyLoomTests.swift          # 30+ tests across all components
├── scripts/                        # Build & notarization scripts
│   ├── build-release.sh
│   └── notarize.sh
├── fastlane/                       # Fastlane automation
│   ├── Fastfile
│   └── Appfile
├── screenshots/                    # Store screenshots
│   ├── final/                      # Final screenshots for download page
│   └── captures/                   # Raw captured screenshots
├── .github/workflows/              # CI/CD
│   ├── ci.yml
│   └── release.yml
├── STORE_DESCRIPTION.md            # App Store listing copy
└── PRIVACY_POLICY.md               # Privacy policy
```

## Customization

All customization is available through the Settings panel (gear icon in the header):
- **Layout**: Key size, spacing, corner radius, font size, keyboard width
- **Style**: Panel radius, key opacity, shadows, 8 font choices, neomorphism
- **Behavior**: Key visibility, start mode, launch at login, quick keys, broken keys
- **Clipboard**: Auto-monitor toggle, max history (100-1000), clear
- **Sounds**: On/off, volume, 6 sound styles with preview

## Troubleshooting

### "KeyLoom is damaged and can't be opened"

This happens because KeyLoom isn't signed with an Apple Developer ID certificate. macOS blocks unsigned apps downloaded from the internet.

**Workaround 1: Right-click to open**
1. Right-click (or Control-click) `KeyLoom.app`
2. Select **Open** from the context menu
3. Click **Open** in the dialog

**Workaround 2: Allow in System Settings**
1. Try to open KeyLoom (it will show the "damaged" error)
2. Open **System Settings > Privacy & Security**
3. Scroll down — you'll see a message about KeyLoom being blocked
4. Click **Open Anyway**

**Workaround 3: Remove quarantine via Terminal**
```bash
xattr -cr /Applications/KeyLoom.app
```
If that doesn't work (macOS may re-apply it), use Workaround 1 or 2.

### Accessibility permission denied

KeyLoom needs Accessibility permission to paste into other apps via Cmd+V simulation. Grant it in:

> System Settings > Privacy & Security > Accessibility > KeyLoom

If KeyLoom doesn't appear in the list, toggle the switch off and on, or restart KeyLoom.

### Keyboard doesn't appear

1. Check the menu bar for the KeyLoom icon (keyboard symbol)
2. Click it to toggle the keyboard visibility
3. If the icon is missing, check System Settings > Control Center > Menu Bar Only

## License

MIT - see [LICENSE](LICENSE)

## Contact

Designed by Fabiconcept (Zayn Favour Ajokubi) - favourajokubi@gmail.com

© 2026 Fabiconcept. All rights reserved.
