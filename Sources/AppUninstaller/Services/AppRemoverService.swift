import Foundation
import AppKit

class AppRemoverService {
    private let fileManager = FileManager.default

    struct FailedItem: Identifiable {
        let id = UUID()
        let url: URL
        let reason: String
        let isPermissionError: Bool
    }

    struct RemovalResult {
        var removedCount: Int = 0
        var failedItems: [FailedItem] = []
        var totalBytesFreed: UInt64 = 0

        var hasPermissionErrors: Bool {
            failedItems.contains { $0.isPermissionError }
        }
    }

    func isAppRunning(_ app: AppInfo) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == app.bundleIdentifier
        }
    }

    func remove(items: [ScanResult]) async -> RemovalResult {
        var result = RemovalResult()

        for item in items where item.isSelected {
            do {
                try fileManager.trashItem(at: item.url, resultingItemURL: nil)
                result.removedCount += 1
                result.totalBytesFreed += item.size
            } catch {
                do {
                    try fileManager.removeItem(at: item.url)
                    result.removedCount += 1
                    result.totalBytesFreed += item.size
                } catch let removeError as NSError {
                    let isPermission = removeError.domain == NSCocoaErrorDomain &&
                        (removeError.code == NSFileWriteNoPermissionError ||
                         removeError.code == NSFileReadNoPermissionError)
                    let reason = isPermission ? "权限不足" : removeError.localizedDescription
                    result.failedItems.append(FailedItem(
                        url: item.url,
                        reason: reason,
                        isPermissionError: isPermission
                    ))
                }
            }
        }

        return result
    }

    func removeWithPrivilege(urls: [URL]) async -> RemovalResult {
        var result = RemovalResult()
        let paths = urls.map { $0.path.replacingOccurrences(of: "'", with: "'\\''") }
        let rmCommands = paths.map { "rm -rf '\($0)'" }.joined(separator: " && ")
        let script = """
            do shell script "\(rmCommands)" with administrator privileges
        """

        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        appleScript?.executeAndReturnError(&errorDict)

        if let error = errorDict {
            let message = error[NSAppleScript.errorMessage] as? String ?? "授权失败"
            for url in urls {
                if fileManager.fileExists(atPath: url.path) {
                    result.failedItems.append(FailedItem(
                        url: url, reason: message, isPermissionError: false
                    ))
                } else {
                    result.removedCount += 1
                }
            }
        } else {
            for url in urls {
                if !fileManager.fileExists(atPath: url.path) {
                    result.removedCount += 1
                    if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
                       let size = attrs[.size] as? UInt64 {
                        result.totalBytesFreed += size
                    }
                } else {
                    result.failedItems.append(FailedItem(
                        url: url, reason: "删除失败", isPermissionError: false
                    ))
                }
            }
        }

        return result
    }
}
