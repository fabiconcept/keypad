import AppKit

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    var isPinned: Bool
    var pinnedAt: Date?

    init(id: UUID = UUID(), text: String, timestamp: Date = Date(), isPinned: Bool = false, pinnedAt: Date? = nil) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.pinnedAt = pinnedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, text, timestamp, isPinned, pinnedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
    }
}

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var items: [ClipboardItem] = []
    private var maxItems: Int { KeyboardSettings.shared.clipboardMaxItems }
    private var timer: Timer?
    private var lastChangeCount: Int
    private var storageURL: URL
    var ignoreNextChange = false

    var sortedItems: [ClipboardItem] {
        items.sorted {
            if $0.isPinned && $1.isPinned {
                return ($0.pinnedAt ?? $0.timestamp) > ($1.pinnedAt ?? $1.timestamp)
            }
            return $0.isPinned && !$1.isPinned
        }
    }

    var pinnedItems: [ClipboardItem] { sortedItems.filter(\.isPinned) }
    var unpinnedItems: [ClipboardItem] { sortedItems.filter { !$0.isPinned } }

    private init() {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appDir = paths[0].appendingPathComponent("com.fabiconcept.keyloom", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        storageURL = appDir.appendingPathComponent("clipboard.json")
        lastChangeCount = NSPasteboard.general.changeCount
        load()
        if KeyboardSettings.shared.clipboardMonitorEnabled {
            startMonitoring()
        }
    }

    func updateMonitoring() {
        if KeyboardSettings.shared.clipboardMonitorEnabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        if ignoreNextChange { ignoreNextChange = false; return }
        guard let text = pb.string(forType: .string), !text.isEmpty else { return }
        if items.first?.text == text { return }
        let item = ClipboardItem(text: text)
        DispatchQueue.main.async { self.addItem(item) }
    }

    func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        let pinned = items.filter(\.isPinned)
        let unpinned = items.filter { !$0.isPinned }
        if unpinned.count > maxItems {
            items = pinned + unpinned.dropLast(unpinned.count - maxItems)
        }
        save()
    }

    func pasteItem(_ item: ClipboardItem) {
        closeClipboard()
        SoundManager.shared.playClipboard()
        KeystrokeSender.shared.paste(item.text)
    }

    func togglePin(_ item: ClipboardItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        if !items[i].isPinned {
            let pinnedCount = items.filter(\.isPinned).count
            guard pinnedCount < 5 else { return }
        }
        items[i].isPinned.toggle()
        items[i].pinnedAt = items[i].isPinned ? Date() : nil
        SoundManager.shared.playClipboardPin()
        save()
    }

    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        SoundManager.shared.playClipboardDelete()
        save()
    }

    func clear() {
        items.removeAll { !$0.isPinned }
        save()
    }

    func saveToFile() {
        let panel = NSSavePanel()
        panel.title = "Save Clipboard History"
        panel.nameFieldStringValue = "clipboard.txt"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        var text = ""
        for item in sortedItems {
            let date = DateFormatter.localizedString(from: item.timestamp, dateStyle: .medium, timeStyle: .short)
            text += "[\(date)]\(item.isPinned ? " [Pinned]" : "")\n\(item.text)\n\n"
        }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        items = decoded
    }
}
