import SwiftUI

struct KeyboardView: View {
    @ObservedObject private var settings = KeyboardSettings.shared
    @ObservedObject private var keyboardState = KeyboardState.shared
    @ObservedObject private var usageTracker = KeyUsageTracker.shared

    private let sender = KeystrokeSender.shared

    var brokenKeyColor: Color {
        switch settings.brokenKeyColor {
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        default: return .blue
        }
    }

    var resolvedFont: Font.Design {
        switch settings.fontFamily {
        case "system": return .default
        case "mono": return .monospaced
        case "georgia": return .serif
        case "courier": return .monospaced
        case "zapfino": return .default
        case "papyrus": return .default
        case "markerfelt": return .default
        default: return .rounded
        }
    }

    var customFontName: String? {
        switch settings.fontFamily {
        case "georgia": return "Georgia"
        case "courier": return "Courier"
        case "zapfino": return "Zapfino"
        case "papyrus": return "Papyrus"
        case "markerfelt": return "Marker Felt"
        default: return nil
        }
    }

    func keyFont(size: CGFloat) -> Font {
        if let name = customFontName {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: .medium, design: resolvedFont)
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(width: 0, height: 0)
                .focusable(false)
            pillHandle
            VStack(spacing: 10) {
                fullKeyboard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: settings.panelCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 8)
    }

    var pillHandle: some View {
        HStack {
            Image(systemName: "keyboard")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Text("KeyLoom")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { showHelp() }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Open help guide")
            Button(action: { openCollapsedPanel() }) {
                Image(systemName: "rectangle.compress.vertical")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Open quick keys panel")
            Button(action: { openClipboard() }) {
                Image(systemName: "clipboard")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Open clipboard history (\(ClipboardManager.shared.items.count))")
            Button(action: { openSettings() }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Open settings")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    var fullKeyboard: some View {
        let visibleRows = settings.showDecorativeKeys ? keyRows : filteredKeyRows
        return VStack(spacing: settings.keySpacing) {
            ForEach(visibleRows, id: \.self) { row in
                let widths = calculateWidths(for: row)
                HStack(spacing: settings.keySpacing) {
                    ForEach(Array(row.enumerated()), id: \.element.id) { index, key in
                        let isDecorative = settings.showDecorativeKeys && (key.type == .backspace || key.type == .tab || key.type == .caps || key.type == .enter)
                        KeyButton(
                            key: key,
                            width: widths[index],
                            height: settings.keySize,
                            cornerRadius: settings.keyCornerRadius,
                            isShifted: keyboardState.isShifted,
                            isCaps: keyboardState.isCaps,
                            isBroken: settings.brokenKeys.contains(key.label),
                            isDecorative: isDecorative,
                            showHighlight: settings.showBrokenKeyHighlight,
                            highlightColor: brokenKeyColor,
                            showShadow: settings.showKeyShadow,
                            opacity: settings.keyOpacity,
                            fontDesign: resolvedFont,
                            customFontName: customFontName,
                            neomorphism: settings.neomorphismEnabled,
                            neoIntensity: settings.neomorphismIntensity,
                            action: { if !isDecorative { handleKey(key) } }
                        )
                    }
                }
            }
        }
    }

    var filteredKeyRows: [[Key]] {
        keyRows.map { row in
            row.filter { key in
                switch key.type {
                case .backspace, .tab, .caps, .enter:
                    return false
                default:
                    return true
                }
            }
        }.filter { !$0.isEmpty }
    }

    func calculateWidths(for row: [Key]) -> [CGFloat] {
        let numKeys = row.count
        let totalSpacing = CGFloat(numKeys - 1) * settings.keySpacing

        if row.count == 1 && row[0].type == .space {
            return [settings.keyboardWidth]
        }

        let totalUnits = row.map(\.relativeWidth).reduce(0, +)
        let unitWidth = (settings.keyboardWidth - totalSpacing) / totalUnits
        return row.map { $0.relativeWidth * unitWidth }
    }

    func handleKey(_ key: Key) {
        usageTracker.recordUse(key.label)
        SoundManager.shared.playKeyPress(keyLabel: key.label)
        switch key.type {
        case .character:
            let useShift = keyboardState.isShifted || (keyboardState.isCaps && key.label.count == 1 && key.label.first?.isLetter == true)
            let char: String = useShift ? (key.shiftLabel ?? key.label.uppercased()) : key.label
            sender.paste(char)
        case .space:
            sender.paste(" ")
        case .enter:
            sender.sendReturn()
        case .tab:
            sender.sendTab()
        case .backspace:
            sender.sendBackspace()
        case .shift:
            keyboardState.isShifted.toggle()
        case .caps:
            keyboardState.isCaps.toggle()
            keyboardState.isShifted = false
        }
    }
}
