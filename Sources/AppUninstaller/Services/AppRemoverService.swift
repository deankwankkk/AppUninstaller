import Foundation
import AppKit

class AppRemoverService {
    private let fileManager = FileManager.default

    struct RemovalResult {
        var removedCount: Int = 0
        var failedItems: [(URL, String)] = []
        var totalBytesFreed: UInt64 = 0
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
                } catch {
                    result.failedItems.append((item.url, error.localizedDescription))
                }
            }
        }

        return result
    }
}
