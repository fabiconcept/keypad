import SwiftUI

// MARK: - Guide Data
struct GuideTip {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let iconBG: Color
    let steps: [String]
}

let guideTips: [GuideTip] = [
    GuideTip(
        title: "Accessibility Access",
        subtitle: "Required for pasting keystrokes",
        icon: "hand.raised.fill",
        iconColor: .orange,
        iconBG: .orange.opacity(0.12),
        steps: [
            "KeyLoom pastes characters using Cmd+V. macOS requires Accessibility permission for this.",
            "Open System Settings",
            "Navigate to Privacy & Security > Accessibility",
            "Click the lock icon and enter your password",
            "Find KeyLoom in the list and toggle it ON",
            "If prompted, restart the app"
        ]
    ),
    GuideTip(
        title: "Broken Keys",
        subtitle: "Highlight the keys you use most",
        icon: "key.fill",
        iconColor: .blue,
        iconBG: .blue.opacity(0.12),
        steps: [
            "Broken keys are displayed in a distinct color so you can spot them instantly.",
            "Open Settings > Layout tab",
            "Scroll to Broken Keys section",
            "Type keys in the text field separated by commas",
            "Pick a highlight color: Blue, Red, Orange, or Purple",
            "Toggle Show Broken Key Highlight to turn the effect on or off"
        ]
    ),
    GuideTip(
        title: "Quick Keys",
        subtitle: "A minimal panel with your top keys",
        icon: "rectangle.dashed",
        iconColor: .green,
        iconBG: .green.opacity(0.12),
        steps: [
            "Quick Keys collapses your keyboard into a tiny floating strip.",
            "Click the minimize icon in the header bar to switch",
            "Or set Start Mode to Quick Keys in Settings > Startup",
            "Choose between 2 to 5 keys",
            "Enable Use Custom Keys to hand-pick which keys appear",
            "Hover over the panel to reveal the header controls"
        ]
    ),
    GuideTip(
        title: "Keyboard Sync",
        subtitle: "Shift and Caps follow your physical keyboard",
        icon: "shift.fill",
        iconColor: .purple,
        iconBG: .purple.opacity(0.12),
        steps: [
            "Your physical Shift and Caps Lock state syncs with KeyLoom in real time.",
            "Hold Shift on your physical keyboard to temporarily shift",
            "The virtual keys will display uppercase letters",
            "Press Caps Lock to lock caps mode on",
            "Press Caps Lock again to turn it off",
            "Works in both expanded and Quick Keys panels"
        ]
    ),
    GuideTip(
        title: "Make It Yours",
        subtitle: "Fonts, neomorphism, sizing and more",
        icon: "slider.horizontal.3",
        iconColor: .pink,
        iconBG: .pink.opacity(0.12),
        steps: [
            "KeyLoom adapts to your style. Here is what you can tweak:",
            "Key size, spacing, corner radius, and opacity",
            "Neomorphism for a raised 3D bevel effect",
            "Font choices: Rounded, System, Mono, Georgia, Courier, Zapfino, Papyrus, Marker Felt",
            "Panel corner radius, shadow, and transparency",
            "Set dark or light mode and a custom start layout"
        ]
    )
]

// MARK: - Welcome Guide (First Launch)
struct WelcomeGuide: View {
    @ObservedObject private var settings = KeyboardSettings.shared
    @State private var currentTip = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            tipContent
            navigationBar
        }
        .frame(width: 460)
    }

    private var headerBar: some View {
        HStack(alignment: .top) {
            Text("Welcome to KeyLoom")
                .font(.system(size: 16, weight: .bold))
            Spacer()
            Button("Skip") {
                settings.hasSeenWelcome = true
                dismiss()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    private var tipContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(guideTips[currentTip].iconBG)
                        .frame(width: 56, height: 56)
                    Image(systemName: guideTips[currentTip].icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(guideTips[currentTip].iconColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(guideTips[currentTip].title)
                        .font(.system(size: 17, weight: .semibold))
                    Text(guideTips[currentTip].subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(guideTips[currentTip].iconColor)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(guideTips[currentTip].steps.enumerated()), id: \.offset) { index, step in
                    if index == 0 {
                        Text(step)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 6)
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(guideTips[currentTip].iconColor.opacity(0.85))
                                    .frame(width: 18, height: 18)
                                Text("\(index)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 2)
                            Text(step)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            ForEach(0..<guideTips.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentTip ? guideTips[currentTip].iconColor : Color.secondary.opacity(0.2))
                    .frame(width: index == currentTip ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentTip)
                    .onTapGesture {
                        withAnimation { currentTip = index }
                    }
            }

            Spacer()

            if currentTip > 0 {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { currentTip -= 1 } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 10, weight: .semibold))
                        Text("Back").font(.system(size: 12))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if currentTip < guideTips.count - 1 {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { currentTip += 1 } }) {
                    HStack(spacing: 4) {
                        Text("Next").font(.system(size: 12))
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Button(action: {
                    settings.hasSeenWelcome = true
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Text("Get Started").font(.system(size: 12, weight: .medium))
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 10, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
}

// MARK: - Help Guide (Button Click)
struct HelpGuide: View {
    @State private var currentTip = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tipContent
            navigationBar
        }
        .frame(width: 460)
    }

    private var tipContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(guideTips[currentTip].iconBG.opacity(0.6))
                        .frame(width: 56, height: 56)
                    Image(systemName: guideTips[currentTip].icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(guideTips[currentTip].iconColor.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(guideTips[currentTip].title)
                        .font(.system(size: 17, weight: .semibold))
                    Text(guideTips[currentTip].subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(guideTips[currentTip].iconColor.opacity(0.7))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(guideTips[currentTip].steps.enumerated()), id: \.offset) { index, step in
                    if index == 0 {
                        Text(step)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 6)
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(guideTips[currentTip].iconColor.opacity(0.5))
                                    .frame(width: 18, height: 18)
                                Text("\(index)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 2)
                            Text(step)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 16)
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            ForEach(0..<guideTips.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentTip ? guideTips[currentTip].iconColor.opacity(0.6) : Color.secondary.opacity(0.15))
                    .frame(width: index == currentTip ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentTip)
                    .onTapGesture {
                        withAnimation { currentTip = index }
                    }
            }

            Spacer()

            if currentTip > 0 {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { currentTip -= 1 } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 10, weight: .semibold))
                        Text("Back").font(.system(size: 12))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if currentTip < guideTips.count - 1 {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { currentTip += 1 } }) {
                    HStack(spacing: 4) {
                        Text("Next").font(.system(size: 12))
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Text("Done").font(.system(size: 12, weight: .medium))
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 10, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
}

// MARK: - Windows
var welcomeWindow: NSWindow?
var helpWindow: NSWindow?

func showWelcome() {
    if let existing = welcomeWindow {
        existing.makeKeyAndOrderFront(nil)
        return
    }

    let panel = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: 440, height: 260),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    panel.title = "Welcome to KeyLoom"
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.center()
    panel.isReleasedWhenClosed = false
    panel.hidesOnDeactivate = false
    panel.contentView?.translatesAutoresizingMaskIntoConstraints = false

    let hostingView = NSHostingView(rootView: WelcomeGuide().tint(.accentColor))
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    panel.contentView = hostingView

    if let contentView = panel.contentView {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: hostingView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: hostingView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: hostingView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: hostingView.bottomAnchor)
        ])
    }

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

func showHelp() {
    if let existing = helpWindow {
        existing.makeKeyAndOrderFront(nil)
        return
    }

    let panel = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: 460, height: 260),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    panel.title = "KeyLoom Guide"
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.center()
    panel.isReleasedWhenClosed = false
    panel.hidesOnDeactivate = false
    panel.contentView?.translatesAutoresizingMaskIntoConstraints = false

    let hostingView = NSHostingView(rootView: HelpGuide().tint(.accentColor))
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    panel.contentView = hostingView

    if let contentView = panel.contentView {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: hostingView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: hostingView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: hostingView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: hostingView.bottomAnchor)
        ])
    }

    NotificationCenter.default.addObserver(
        forName: NSWindow.willCloseNotification,
        object: panel,
        queue: .main
    ) { _ in
        helpWindow = nil
    }

    panel.orderFront(nil)
    helpWindow = panel
}
