# KeyLoom - Floating Virtual Keyboard for macOS

A native macOS floating keyboard panel that lives above all windows, accessible from the menu bar, works across every app.

## Features
- Floats above all windows
- Menu bar icon (⌨) - click to show/hide
- Full QWERTY layout with Shift, Caps Lock, Tab, Enter
- Broken keys (T, t, 5, %) are highlighted in blue for easy access
- Type in the output box, then **Copy & Paste** directly into any app
- Collapsible with the ↑ chevron
- Drag anywhere by the title bar
- Works in all spaces / full-screen apps
- Supports dark mode

## Requirements
- macOS 13 Ventura or later
- Xcode 15 or later

## Build & Run

### Option 1: Xcode (recommended)
1. Open `KeyLoom.xcodeproj` in Xcode
2. Select your Mac as the run destination
3. Press **⌘R** to build and run
4. The app appears in your menu bar (keyboard icon ⌨)

### Option 2: Command line
```bash
xcodebuild -project KeyLoom.xcodeproj -scheme KeyLoom -configuration Release build
```

## First-time Setup
On first launch, macOS may ask for **Accessibility permissions** so the app can paste into other apps via Cmd+V simulation. Grant this in:

> System Settings → Privacy & Security → Accessibility → KeyLoom ✓

Without this, the **Copy & Paste** button still copies to clipboard - just paste manually with ⌘V.

## Usage
1. Click the ⌨ icon in the menu bar to show the panel
2. Click keys to build your text in the output box
3. Hit **Copy & Paste** - your text is pasted directly into the active app
4. Or use **Copy** and manually paste with ⌘V

## Customization
To change which keys are "broken" (highlighted in blue), edit `KeyboardView.swift`:
```swift
let brokenKeys: Set<String> = ["t", "T", "5", "%"]
```
Add or remove any keys you need.
