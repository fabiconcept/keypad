import AppKit
import CoreGraphics

struct KeystrokeSender {
    static let shared = KeystrokeSender()

    func paste(_ text: String) {
        NSPasteboard.general.clearContents()
        ClipboardManager.shared.ignoreNextChange = true
        NSPasteboard.general.setString(text, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let src = CGEventSource(stateID: .combinedSessionState)
            let vKeyCode: CGKeyCode = 9
            let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true)
            let cmdUp   = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false)
            cmdDown?.flags = .maskCommand
            cmdUp?.flags   = .maskCommand
            cmdDown?.post(tap: .cghidEventTap)
            cmdUp?.post(tap: .cghidEventTap)
        }
    }

    func sendBackspace() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 51, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 51, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    func sendTab() { paste("\t") }
    func sendReturn() { paste("\n") }
}
