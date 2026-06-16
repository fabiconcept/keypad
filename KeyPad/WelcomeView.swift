import SwiftUI

// MARK: - Welcome/Tip View
struct WelcomeView: View {
    @ObservedObject private var settings = KeyboardSettings.shared
    @State private var currentTip = 0
    @Environment(\.dismiss) private var dismiss

    private let tips: [(title: String, subtitle: String, icon: String, iconColor: Color, iconBG: Color, steps: [String])] = [
        (
            "Accessibility Access",
            "Required for pasting keystrokes",
            "hand.raised.filled",
            .orange,
            .orange.opacity(0.12),
            [
                "KeyPad pastes characters using Cmd+V. macOS requires Accessibility permission for this.",
                "Open System Settings",
                "Navigate to Privacy & Security > Accessibility",
                "Click the lock icon and enter your password",
                "Find KeyPad in the list and toggle it ON",
                "If prompted, restart the app"
            ]
        ),
        (
            "Broken Keys",
            "Highlight the keys you use most",
            "key.fill",
            .blue,
            .blue.opacity(0.12),
            [
                "Broken keys are displayed in a distinct color so you can spot them instantly.",
                "Open Settings > Layout tab",
                "Scroll to Broken Keys section",
                "Type keys in the text field separated by commas",
                "Pick a highlight color: Blue, Red, Orange, or Purple",
                "Toggle Show Broken Key Highlight to turn the effect on or off"
            ]
        ),
        (
            "Quick Keys",
            "A minimal panel with your top keys",
            "rectangle.ratio.1x1",
            .green,
            .green.opacity(0.12),
            [
                "Quick Keys collapses your keyboard into a tiny floating strip.",
                "Click the minimize icon in the header bar to switch",
                "Or set Start Mode to Quick Keys in Settings > Startup",
                "Choose between 2 to 5 keys",
                "Enable Use Custom Keys to hand-pick which keys appear",
                "Hover over the panel to reveal the header controls"
            ]
        ),
        (
            "Keyboard Sync",
            "Shift and Caps follow your physical keyboard",
            "option.shift.fill",
            .purple,
            .purple.opacity(0.12),
            [
                "Your physical Shift and Caps Lock state syncs with KeyPad in real time.",
                "Hold Shift on your physical keyboard to temporarily shift",
                "The virtual keys will display uppercase letters",
                "Press Caps Lock to lock caps mode on",
                "Press Caps Lock again to turn it off",
                "Works in both expanded and Quick Keys panels"
            ]
        ),
        (
            "Make It Yours",
            "Fonts, neomorphism, sizing and more",
            "slider.horizontal.3",
            .pink,
            .pink.opacity(0.12),
            [
                "KeyPad adapts to your style. Here is what you can tweak:",
                "Key size, spacing, corner radius, and opacity",
                "Neomorphism for a raised 3D bevel effect",
                "Font choices: Rounded, System, Mono, Georgia, Courier, Zapfino, Papyrus, Marker Felt",
                "Panel corner radius, shadow, and transparency",
                "Set dark or light mode and a custom start layout"
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            tipContent
            Divider()
            navigationBar
        }
        .frame(width: 520, height: 460)
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Welcome to KeyPad")
                    .font(.system(size: 18, weight: .bold))
                Text("A quick tour of every feature")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Skip") {
                settings.hasSeenWelcome = true
                dismiss()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var tipContent: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(tips[currentTip].iconBG)
                            .frame(width: 72, height: 72)
                        Image(systemName: tips[currentTip].icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(tips[currentTip].iconColor)
                    }

                    Text("\(currentTip + 1)/\(tips.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 72)
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text(tips[currentTip].title)
                        .font(.system(size: 17, weight: .semibold))

                    Text(tips[currentTip].subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(tips[currentTip].iconColor)
                        .padding(.bottom, 6)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(tips[currentTip].steps.enumerated()), id: \.offset) { index, step in
                            if index == 0 {
                                Text(step)
                                    .font(.system(size: 12.5))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 8)
                            } else {
                                HStack(alignment: .top, spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(tips[currentTip].iconColor.opacity(0.85))
                                            .frame(width: 20, height: 20)
                                        Text("\(index)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.top, 1)
                                    Text(step)
                                        .font(.system(size: 12.5))
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.bottom, 5)
                            }
                        }
                    }
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            ForEach(0..<tips.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentTip ? tips[currentTip].iconColor : Color.secondary.opacity(0.2))
                    .frame(width: index == currentTip ? 24 : 8, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentTip)
                    .onTapGesture {
                        withAnimation { currentTip = index }
                    }
            }

            Spacer()

            if currentTip > 0 {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { currentTip -= 1 } }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if currentTip < tips.count - 1 {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { currentTip += 1 } }) {
                    Text("Next")
                        .font(.system(size: 12))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Button(action: {
                    settings.hasSeenWelcome = true
                    dismiss()
                }) {
                    Text("Get Started")
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }
}

// MARK: - Welcome Window
var welcomeWindow: NSWindow?

func showWelcome() {
    if let existing = welcomeWindow {
        existing.makeKeyAndOrderFront(nil)
        return
    }

    let panel = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    panel.title = "Welcome to KeyPad"
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.center()
    panel.isReleasedWhenClosed = false

    let hostingView = NSHostingView(rootView: WelcomeView())
    panel.contentView = hostingView

    NotificationCenter.default.addObserver(
        forName: NSWindow.willCloseNotification,
        object: panel,
        queue: .main
    ) { _ in
        welcomeWindow = nil
    }

    panel.orderFront(nil)
    welcomeWindow = panel
}
