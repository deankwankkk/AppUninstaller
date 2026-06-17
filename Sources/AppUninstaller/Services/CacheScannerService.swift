import Foundation

struct CacheItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let category: CacheCategory
    let size: UInt64
    var isSelected: Bool = true

    var displayPath: String {
        url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

enum CacheCategory: String, CaseIterable {
    case userCache = "应用缓存"
    case logs = "系统日志"
    case downloadedMail = "邮件下载"
    case xcode = "Xcode 缓存"
    case browser = "浏览器缓存"
    case systemCache = "系统缓存"

    var icon: String {
        switch self {
        case .userCache: return "internaldrive"
        case .logs: return "doc.text"
        case .downloadedMail: return "envelope"
        case .xcode: return "hammer"
        case .browser: return "globe"
        case .systemCache: return "gearshape.2"
        }
    }
}

class CacheScannerService {
    private let fileManager = FileManager.default
    private let home = NSHomeDirectory()

    func scanAllCaches() async -> [CacheItem] {
        var items: [CacheItem] = []

        await withTaskGroup(of: [CacheItem].self) { group in
            group.addTask { self.scanUserCaches() }
            group.addTask { self.scanLogs() }
            group.addTask { self.scanXcodeCache() }
            group.addTask { self.scanBrowserCaches() }

            for await result in group {
                items.append(contentsOf: result)
            }
        }

        return items.sorted { $0.size > $1.size }
    }

    func scanCustomDirectory(at url: URL) async -> [CacheItem] {
        let path = url.path
        guard fileManager.fileExists(atPath: path) else { return [] }
        guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
            let size = directorySize(at: url)
            if size > 0 {
                return [CacheItem(url: url, name: url.lastPathComponent, category: .userCache, size: size)]
            }
            return []
        }

        var items: [CacheItem] = []
        for name in contents {
            let itemURL = url.appendingPathComponent(name)
            let size = directorySize(at: itemURL)
            if size > 0 {
                items.append(CacheItem(url: itemURL, name: name, category: .userCache, size: size))
            }
        }
        return items.sorted { $0.size > $1.size }
    }

    private func scanUserCaches() -> [CacheItem] {
        let cachePath = "\(home)/Library/Caches"
        return scanDirectory(path: cachePath, category: .userCache)
    }

    private func scanLogs() -> [CacheItem] {
        let logPath = "\(home)/Library/Logs"
        return scanDirectory(path: logPath, category: .logs)
    }

    private func scanXcodeCache() -> [CacheItem] {
        var items: [CacheItem] = []
        let paths = [
            "\(home)/Library/Developer/Xcode/DerivedData",
            "\(home)/Library/Developer/Xcode/Archives",
            "\(home)/Library/Developer/CoreSimulator/Caches",
        ]
        for path in paths {
            let url = URL(fileURLWithPath: path)
            guard fileManager.fileExists(atPath: path) else { continue }
            let size = directorySize(at: url)
            if size > 0 {
                items.append(CacheItem(
                    url: url,
                    name: url.lastPathComponent,
                    category: .xcode,
                    size: size
                ))
            }
        }
        return items
    }

    private func scanBrowserCaches() -> [CacheItem] {
        var items: [CacheItem] = []
        let paths = [
            ("\(home)/Library/Caches/Google/Chrome", "Chrome 缓存"),
            ("\(home)/Library/Caches/com.apple.Safari", "Safari 缓存"),
            ("\(home)/Library/Caches/Firefox", "Firefox 缓存"),
            ("\(home)/Library/Caches/Microsoft Edge", "Edge 缓存"),
        ]
        for (path, name) in paths {
            let url = URL(fileURLWithPath: path)
            guard fileManager.fileExists(atPath: path) else { continue }
            let size = directorySize(at: url)
            if size > 1_000_000 {
                items.append(CacheItem(url: url, name: name, category: .browser, size: size))
            }
        }
        return items
    }

    private func scanDirectory(path: String, category: CacheCategory) -> [CacheItem] {
        guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else { return [] }
        var items: [CacheItem] = []
        for name in contents {
            let url = URL(fileURLWithPath: path).appendingPathComponent(name)
            let size = directorySize(at: url)
            if size > 500_000 {
                items.append(CacheItem(url: url, name: name, category: category, size: size))
            }
        }
        return items
    }

    private func directorySize(at url: URL) -> UInt64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        guard isDir.boolValue else {
            return (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? 0
        }
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if values?.isDirectory == false {
                total += UInt64(values?.fileSize ?? 0)
            }
        }
        return total
    }

    func clearCaches(items: [CacheItem]) async -> (cleared: Int, freed: UInt64, failed: Int) {
        var cleared = 0
        var freed: UInt64 = 0
        var failed = 0

        for item in items where item.isSelected {
            do {
                try fileManager.trashItem(at: item.url, resultingItemURL: nil)
                cleared += 1
                freed += item.size
            } catch {
                do {
                    try fileManager.removeItem(at: item.url)
                    cleared += 1
                    freed += item.size
                } catch {
                    failed += 1
                }
            }
        }

        return (cleared, freed, failed)
    }
}
