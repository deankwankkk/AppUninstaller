import Foundation
import SwiftUI

enum CacheState {
    case idle
    case scanning
    case results
    case clearing
    case completed
}

@MainActor
class CacheViewModel: ObservableObject {
    @Published var cacheItems: [CacheItem] = []
    @Published var state: CacheState = .idle
    @Published var showConfirmation = false
    @Published var clearResult: (cleared: Int, freed: UInt64, failed: Int)?
    @Published var customDirectories: [URL] = []

    private let service = CacheScannerService()

    var selectedItems: [CacheItem] {
        cacheItems.filter { $0.isSelected }
    }

    var totalSize: UInt64 {
        cacheItems.reduce(0) { $0 + $1.size }
    }

    var selectedSize: UInt64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }

    var groupedItems: [(CacheCategory, [CacheItem])] {
        let grouped = Dictionary(grouping: cacheItems) { $0.category }
        return CacheCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    func scan() {
        state = .scanning
        cacheItems = []
        Task {
            var items = await service.scanAllCaches()
            for dir in customDirectories {
                let dirItems = await service.scanCustomDirectory(at: dir)
                items.append(contentsOf: dirItems)
            }
            cacheItems = items.sorted { $0.size > $1.size }
            state = .results
        }
    }

    func scanDirectory(_ url: URL) {
        if !customDirectories.contains(url) {
            customDirectories.append(url)
        }
        scan()
    }

    func removeCustomDirectory(_ url: URL) {
        customDirectories.removeAll { $0 == url }
    }

    func confirmClear() {
        showConfirmation = true
    }

    func executeClear() {
        state = .clearing
        showConfirmation = false
        Task {
            let result = await service.clearCaches(items: selectedItems)
            clearResult = result
            state = .completed
        }
    }

    func reset() {
        cacheItems = []
        state = .idle
        clearResult = nil
    }

    func toggleItem(id: UUID) {
        if let index = cacheItems.firstIndex(where: { $0.id == id }) {
            cacheItems[index].isSelected.toggle()
        }
    }

    func selectAll() {
        for i in cacheItems.indices { cacheItems[i].isSelected = true }
    }

    func deselectAll() {
        for i in cacheItems.indices { cacheItems[i].isSelected = false }
    }
}
