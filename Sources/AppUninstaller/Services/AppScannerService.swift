import Foundation

class AppScannerService {
    private let fileManager = FileManager.default
    private let home = NSHomeDirectory()

    struct ScanLocation {
        let path: String
        let category: FileCategory
    }

    func scan(app: AppInfo) async -> [ScanResult] {
        let bundleID = app.bundleIdentifier.lowercased()
        let appName = app.name.lowercased()

        let searchTerms = buildSearchTerms(bundleID: bundleID, appName: appName)
        let locations = scanLocations()

        var results: [ScanResult] = []

        let appSize = directorySize(at: app.path)
        results.append(ScanResult(url: app.path, category: .appBundle, size: appSize))

        await withTaskGroup(of: [ScanResult].self) { group in
            for location in locations {
                group.addTask { [self] in
                    self.scanDirectory(location: location, searchTerms: searchTerms)
                }
            }
            for await locationResults in group {
                results.append(contentsOf: locationResults)
            }
        }

        return results
    }

    private func buildSearchTerms(bundleID: String, appName: String) -> [String] {
        var terms = [bundleID, appName]
        let components = bundleID.components(separatedBy: ".")
        if components.count >= 3 {
            let withoutFirst = components.dropFirst().joined(separator: ".")
            terms.append(withoutFirst)
        }
        return terms
    }

    private func scanLocations() -> [ScanLocation] {
        [
            ScanLocation(path: "\(home)/Library/Preferences", category: .preferences),
            ScanLocation(path: "\(home)/Library/Caches", category: .caches),
            ScanLocation(path: "\(home)/Library/Application Support", category: .applicationSupport),
            ScanLocation(path: "\(home)/Library/Logs", category: .logs),
            ScanLocation(path: "\(home)/Library/Containers", category: .containers),
            ScanLocation(path: "\(home)/Library/Group Containers", category: .groupContainers),
            ScanLocation(path: "\(home)/Library/LaunchAgents", category: .launchAgents),
            ScanLocation(path: "\(home)/Library/Saved Application State", category: .savedState),
            ScanLocation(path: "\(home)/Library/HTTPStorages", category: .httpStorages),
            ScanLocation(path: "\(home)/Library/WebKit", category: .webKit),
            ScanLocation(path: "\(home)/Library/Cookies", category: .cookies),
        ]
    }

    private func scanDirectory(location: ScanLocation, searchTerms: [String]) -> [ScanResult] {
        guard fileManager.fileExists(atPath: location.path) else { return [] }
        guard let contents = try? fileManager.contentsOfDirectory(atPath: location.path) else { return [] }

        var results: [ScanResult] = []
        for item in contents {
            let itemLower = item.lowercased()
            let matched: Bool

            if location.category == .groupContainers {
                let stripped = stripTeamID(from: itemLower)
                matched = searchTerms.contains { stripped.contains($0) }
            } else {
                matched = searchTerms.contains { term in
                    itemLower.contains(term)
                }
            }

            if matched {
                let fullURL = URL(fileURLWithPath: location.path).appendingPathComponent(item)
                let size = fileSize(at: fullURL)
                results.append(ScanResult(url: fullURL, category: location.category, size: size))
            }
        }
        return results
    }

    private func stripTeamID(from name: String) -> String {
        let parts = name.components(separatedBy: ".")
        guard parts.count > 1 else { return name }
        let firstPart = parts[0]
        if firstPart.count == 10 && firstPart.allSatisfy({ $0.isLetter || $0.isNumber }) {
            return parts.dropFirst().joined(separator: ".")
        }
        return name
    }

    private func fileSize(at url: URL) -> UInt64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        if isDir.boolValue {
            return directorySize(at: url)
        }
        return (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? 0
    }

    private func directorySize(at url: URL) -> UInt64 {
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
}
