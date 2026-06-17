import Foundation

class AppDiscoveryService {
    private let fileManager = FileManager.default

    func discoverApps() -> [AppInfo] {
        var apps: [AppInfo] = []
        let searchPaths = [
            "/Applications",
            NSHomeDirectory() + "/Applications"
        ]

        for searchPath in searchPaths {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: URL(fileURLWithPath: searchPath),
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents where url.pathExtension == "app" {
                if let appInfo = AppInfo(at: url) {
                    if !isSystemApp(appInfo) {
                        apps.append(appInfo)
                    }
                }
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func appInfo(from url: URL) -> AppInfo? {
        guard url.pathExtension == "app" else { return nil }
        return AppInfo(at: url)
    }

    private func isSystemApp(_ app: AppInfo) -> Bool {
        let systemBundlePrefixes = [
            "com.apple."
        ]
        return systemBundlePrefixes.contains { app.bundleIdentifier.hasPrefix($0) }
    }
}
