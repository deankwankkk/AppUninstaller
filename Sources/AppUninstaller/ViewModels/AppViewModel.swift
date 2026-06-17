import Foundation
import SwiftUI
import AppKit

enum AppState {
    case idle
    case scanning
    case results
    case removing
    case completed
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var installedApps: [AppInfo] = []
    @Published var selectedApp: AppInfo?
    @Published var scanResults: [ScanResult] = []
    @Published var state: AppState = .idle
    @Published var searchText = ""
    @Published var removalResult: AppRemoverService.RemovalResult?
    @Published var showConfirmation = false
    @Published var errorMessage: String?

    private let discoveryService = AppDiscoveryService()
    private let scannerService = AppScannerService()
    private let removerService = AppRemoverService()

    var filteredApps: [AppInfo] {
        if searchText.isEmpty { return installedApps }
        return installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedItems: [ScanResult] {
        scanResults.filter { $0.isSelected }
    }

    var totalSelectedSize: UInt64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }

    var groupedResults: [(FileCategory, [ScanResult])] {
        let grouped = Dictionary(grouping: scanResults) { $0.category }
        return FileCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    func loadApps() {
        installedApps = discoveryService.discoverApps()
    }

    func selectApp(_ app: AppInfo) {
        selectedApp = app
        scanResults = []
        state = .scanning
        Task {
            scanResults = await scannerService.scan(app: app)
            state = .results
        }
    }

    func handleDrop(url: URL) {
        guard let app = discoveryService.appInfo(from: url) else {
            errorMessage = "无法识别该应用"
            return
        }
        selectApp(app)
    }

    func confirmRemoval() {
        guard let app = selectedApp else { return }
        if removerService.isAppRunning(app) {
            errorMessage = "\(app.name) 正在运行，请先退出应用再卸载"
            return
        }
        showConfirmation = true
    }

    func executeRemoval() {
        state = .removing
        showConfirmation = false
        Task {
            let result = await removerService.remove(items: selectedItems)
            removalResult = result
            state = .completed
        }
    }

    func reset() {
        selectedApp = nil
        scanResults = []
        state = .idle
        removalResult = nil
        errorMessage = nil
        loadApps()
    }

    func toggleItem(id: UUID) {
        if let index = scanResults.firstIndex(where: { $0.id == id }) {
            scanResults[index].isSelected.toggle()
        }
    }

    func selectAll() {
        for i in scanResults.indices {
            scanResults[i].isSelected = true
        }
    }

    func deselectAll() {
        for i in scanResults.indices {
            scanResults[i].isSelected = false
        }
    }
}
