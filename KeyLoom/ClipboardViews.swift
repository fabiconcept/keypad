import SwiftUI

var clipboardWindow: NSWindow?

extension NSPasteboard.PasteboardType {
    static let keyloomSearchPasteboard: NSPasteboard.PasteboardType = .init("com.fabiconcept.keyloom.searchPasteboard")
}

struct ClipboardHistoryView: View {
    @ObservedObject private var clipboard = ClipboardManager.shared
    @State private var searchText = ""
    @State private var hoveredItem: UUID?
    @FocusState private var searchFocused: Bool

    var filteredItems: [ClipboardItem] {
        let source = clipboard.sortedItems
        if searchText.isEmpty { return source }
        return source.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var pinnedItems: [ClipboardItem] { clipboard.pinnedItems.filter { searchText.isEmpty || $0.text.localizedCaseInsensitiveContains(searchText) } }
    var unpinnedItems: [ClipboardItem] { clipboard.unpinnedItems.filter { searchText.isEmpty || $0.text.localizedCaseInsensitiveContains(searchText) } }
    var hasPinned: Bool { !pinnedItems.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "clipboard")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text("Clipboard")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if !clipboard.items.isEmpty {
                    Button(action: { clipboard.saveToFile() }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .help("Save clipboard to file")
                    Button(role: .destructive, action: { clipboard.clear() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .help("Clear clipboard history")
                }
                Button(action: { closeClipboard() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            SearchField(text: $searchText, isFocused: $searchFocused)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text(searchText.isEmpty ? "Empty" : "No matches")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        if hasPinned {
                            Section {
                                ForEach(pinnedItems) { item in
                                    ClipboardRow(item: item, hoveredItem: $hoveredItem)
                                }
                            } header: {
                                ClipboardSectionHeader(title: "PINNED", count: pinnedItems.count)
                            }
                            Divider().padding(.vertical, 2)
                        }
                        Section {
                            ForEach(unpinnedItems) { item in
                                ClipboardRow(item: item, hoveredItem: $hoveredItem)
                            }
                        } header: {
                            if hasPinned {
                                ClipboardSectionHeader(title: "RECENT", count: unpinnedItems.count)
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(width: 300, height: 380)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 5)
        .onAppear { searchFocused = true }
    }
}

struct ClipboardSectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
                .kerning(1)
            Text("\(count)")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary.opacity(0.35))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct SearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
            TextField("", text: $text, prompt: Text("Search").font(.system(size: 11)).foregroundColor(.secondary.opacity(0.4)))
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .focused(isFocused)
            if !text.isEmpty {
                Button(action: { text = ""; isFocused.wrappedValue = true }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

struct ClipboardRow: View {
    let item: ClipboardItem
    @Binding var hoveredItem: UUID?
    @ObservedObject private var clipboard = ClipboardManager.shared

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { clipboard.pasteItem(item) }) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(item.isPinned ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                        .frame(width: 3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.text)
                            .font(.system(size: 11))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .foregroundColor(.primary)
                        Text(item.timestamp, style: .relative)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                Button(action: { clipboard.togglePin(item) }) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 9))
                        .foregroundColor(item.isPinned ? .accentColor : .secondary.opacity(0.4))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin" : "Pin")

                Button(action: { clipboard.deleteItem(item) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.4))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
            .padding(.trailing, 6)
            .opacity(hoveredItem == item.id ? 1 : 0)
            .animation(.easeInOut(duration: 0.1), value: hoveredItem)
        }
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hoveredItem == item.id ? Color.primary.opacity(0.06) : .clear)
                .padding(.horizontal, 6)
        )
        .onHover { hovering in
            hoveredItem = hovering ? item.id : nil
        }
    }
}

class ClipboardFocusPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

func openClipboard() {
    if let existing = clipboardWindow {
        existing.orderFrontRegardless()
        return
    }

    let panel = ClipboardFocusPanel(
        contentRect: NSRect(x: 0, y: 0, width: 300, height: 380),
        styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
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
    panel.titleVisibility = .hidden
    panel.titlebarAppearsTransparent = true
    panel.worksWhenModal = true
    panel.hidesOnDeactivate = false
    panel.isReleasedWhenClosed = false

    let hostingView = NSHostingView(rootView: ClipboardHistoryView())
    panel.contentView = hostingView

    if let screen = NSScreen.main {
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - 320
        let y = screenFrame.midY - 190
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    NotificationCenter.default.addObserver(
        forName: NSWindow.didMoveNotification,
        object: panel,
        queue: .main
    ) { _ in
        let origin = panel.frame.origin
        UserDefaults.standard.set(["x": origin.x, "y": origin.y], forKey: "clipboardPanelFrame")
    }

    panel.orderFrontRegardless()
    clipboardWindow = panel
}

func closeClipboard() {
    clipboardWindow?.orderOut(nil)
    clipboardWindow = nil
}
