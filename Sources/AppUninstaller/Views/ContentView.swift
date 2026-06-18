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
            if let result = viewModel.removalResult {
                if result.failedItems.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                    Text("卸载完成")
                        .font(.title.bold())
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.orange)
                    Text("部分文件卸载失败")
                        .font(.title.bold())
                }

                VStack(spacing: 8) {
                    if result.removedCount > 0 {
                        Text("已移除 \(result.removedCount) 个项目")
                        Text("释放空间: \(formattedSize(result.totalBytesFreed))")
                            .foregroundStyle(.secondary)
                    }
                }

                if !result.failedItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("失败项目 (\(result.failedItems.count))")
                            .font(.headline)
                            .foregroundStyle(.red)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(result.failedItems) { item in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: item.isPermissionError ? "lock.fill" : "xmark.circle.fill")
                                            .foregroundStyle(item.isPermissionError ? .orange : .red)
                                            .font(.caption)
                                            .frame(width: 14, alignment: .center)
                                            .padding(.top, 2)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.url.path)
                                                .font(.system(.caption, design: .monospaced))
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                            Text(item.reason)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(10)
                        }
                        .frame(maxHeight: 160)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .frame(maxWidth: 500)

                    if result.hasPermissionErrors {
                        Button {
                            viewModel.retryWithPrivilege()
                        } label: {
                            Label("以管理员权限重试", systemImage: "lock.open.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
            }

            Button("完成") {
                viewModel.reset()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func formattedSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
