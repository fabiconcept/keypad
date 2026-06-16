import SwiftUI
import AppKit
import ApplicationServices

// MARK: - Focus Manager
class FocusManager {
    static let shared = FocusManager()
    private var savedElement: AXUIElement?
    private var savedPID: pid_t = 0

    func snapshot() {
        let sys = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &focused)
        if result == .success, let element = focused {
            savedElement = (element as! AXUIElement)
            AXUIElementGetPid(element as! AXUIElement, &savedPID)
        } else {
            savedElement = nil
            savedPID = 0
        }
    }

    func restore() {
        guard let element = savedElement else { return }
        let axResult = AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, true as CFTypeRef)
        if axResult == .success { return }
        if savedPID != 0, let app = NSRunningApplication(processIdentifier: savedPID) {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }
}

// MARK: - App
@main
struct KeyPadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingWindow: NSWindow?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusBar()
        showFloatingPanel()
        let startMode = UserDefaults.standard.string(forKey: "startMode") ?? "expanded"
        if startMode == "collapsed" {
            openCollapsedPanel()
        }

        // Show welcome screen on first launch
        let hasSeenWelcome = UserDefaults.standard.object(forKey: "hasSeenWelcome") as? Bool ?? false
        if !hasSeenWelcome {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showWelcome()
            }
        }
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyPad")
            button.action = #selector(togglePanel)
            button.target = self

            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Show Keyboard", action: #selector(togglePanel), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Show Tips", action: #selector(showTips), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "About KeyPad", action: #selector(showAbout), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit KeyPad", action: #selector(quitApp), keyEquivalent: "q"))
            button.menu = menu
        }
    }

    @objc func showTips() {
        showWelcome()
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "KeyPad"
        alert.informativeText = "Version 1.0.0\n\nA floating virtual keyboard for macOS.\nType directly into any app with clipboard paste.\n\nDesigned by Fabiconcept (Zayn Favour Ajokubi)\nfavourajokubi@gmail.com\n\n© 2026 Fabiconcept. All rights reserved."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.icon = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
        alert.runModal()
    }

    @objc func quitApp() {
        let alert = NSAlert()
        alert.messageText = "Quit KeyPad?"
        alert.informativeText = "Are you sure you want to quit KeyPad?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        alert.icon = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
        if alert.runModal() == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }

    @objc func togglePanel() {
        if let collapsedWin = collapsedWindow, collapsedWin.isVisible {
            closeCollapsedPanel()
        } else if let floatingWin = floatingWindow, floatingWin.isVisible {
            floatingWin.orderOut(nil)
        } else if let floatingWin = floatingWindow {
            floatingWin.orderFront(nil)
        }
    }

    func showFloatingPanel() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 524, height: 260),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        let hostingView = NSHostingView(rootView: KeyboardView())
        panel.contentView = hostingView

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 262
            let y = screenFrame.maxY - 280
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
        floatingWindow = panel
        mainWindow = panel
    }
}

// MARK: - Floating Panel
class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func mouseDown(with event: NSEvent) {
        FocusManager.shared.snapshot()
        super.mouseDown(with: event)
    }
}
