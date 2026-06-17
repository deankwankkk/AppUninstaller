import Foundation

struct ScanResult: Identifiable {
    let id = UUID()
    let url: URL
    let category: FileCategory
    let size: UInt64
    var isSelected: Bool = true

    var displayPath: String {
        url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

enum FileCategory: String, CaseIterable {
    case appBundle = "应用本体"
    case preferences = "偏好设置"
    case caches = "缓存"
    case applicationSupport = "应用支持"
    case logs = "日志"
    case containers = "容器"
    case groupContainers = "群组容器"
    case launchAgents = "启动代理"
    case savedState = "保存状态"
    case httpStorages = "HTTP 存储"
    case webKit = "WebKit"
    case cookies = "Cookies"
    case other = "其他"

    var icon: String {
        switch self {
        case .appBundle: return "app.badge"
        case .preferences: return "gearshape"
        case .caches: return "internaldrive"
        case .applicationSupport: return "folder"
        case .logs: return "doc.text"
        case .containers: return "shippingbox"
        case .groupContainers: return "shippingbox.fill"
        case .launchAgents: return "bolt"
        case .savedState: return "clock.arrow.circlepath"
        case .httpStorages: return "network"
        case .webKit: return "safari"
        case .cookies: return "circle.grid.cross"
        case .other: return "questionmark.folder"
        }
    }
}
