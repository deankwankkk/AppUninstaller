import SwiftUI

enum AppTab: String, CaseIterable {
    case uninstall = "卸载应用"
    case cache = "清除缓存"

    var icon: String {
        switch self {
        case .uninstall: return "trash"
        case .cache: return "externaldrive.badge.xmark"
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var selectedTab: AppTab = .uninstall

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                switch selectedTab {
                case .uninstall:
                    AppListView(viewModel: viewModel)
                case .cache:
                    CacheSidebarView()
                }
            }
        } detail: {
            switch selectedTab {
            case .uninstall:
                uninstallDetailView
            case .cache:
                CacheView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            viewModel.loadApps()
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showConfirmation) {
            ConfirmationSheet(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var uninstallDetailView: some View {
        switch viewModel.state {
        case .idle:
            DropZoneView(viewModel: viewModel)
        case .scanning:
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("正在扫描关联文件...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        case .results:
            ScanResultsView(viewModel: viewModel)
        case .removing:
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("正在卸载...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        case .completed:
            CompletedView(viewModel: viewModel)
        }
    }
}

struct CacheSidebarView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "externaldrive.badge.xmark")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("缓存清理")
                .font(.headline)
            Text("扫描并清除应用缓存、日志等临时文件")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct ConfirmationSheet: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("确认卸载")
                .font(.title2.bold())

            Text("将移除 \(viewModel.selectedItems.count) 个项目，释放 \(formattedSize(viewModel.totalSelectedSize)) 空间")
                .foregroundStyle(.secondary)

            Text("文件将移至废纸篓，可从废纸篓恢复")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: 16) {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("确认卸载") {
                    viewModel.executeRemoval()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(30)
        .frame(width: 380)
    }

    private func formattedSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

struct CompletedView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("卸载完成")
                .font(.title.bold())

            if let result = viewModel.removalResult {
                VStack(spacing: 8) {
                    Text("已移除 \(result.removedCount) 个项目")
                    Text("释放空间: \(formattedSize(result.totalBytesFreed))")
                        .foregroundStyle(.secondary)

                    if !result.failedItems.isEmpty {
                        Text("\(result.failedItems.count) 个项目移除失败")
                            .foregroundStyle(.red)
                    }
                }
            }

            Button("完成") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func formattedSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
