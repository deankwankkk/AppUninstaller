import Foundation
import AppKit

struct AppInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let path: URL
    let icon: NSImage?
    let version: String?

    init?(at url: URL) {
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else {
            return nil
        }
        self.id = bundleID
        self.bundleIdentifier = bundleID
        self.name = bundle.infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle.infoDictionary?["CFBundleName"] as? String
            ?? url.deletingPathExtension().lastPathComponent
        self.path = url
        self.version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
    }

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
