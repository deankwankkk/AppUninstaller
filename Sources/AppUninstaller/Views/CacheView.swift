import SwiftUI
import AppKit

struct CacheView: View {
    @StateObject private var viewModel = CacheViewModel()

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.state {
            case .idle:
                cacheIdleView
            case .scanning:
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("正在扫描缓存...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .results:
                cacheResultsView
            case .clearing:
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("正在清除缓存...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .completed:
                cacheCompletedView
            }
        }
        .sheet(isPresented: $viewModel.showConfirmation) {
            CacheClearConfirmSheet(viewModel: viewModel)
        }
    }

    private var cacheIdleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash.circle")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("缓存清理")
                .font(.title2.bold())

            Text("扫描系统中的应用缓存、日志及临时文件")
                .foregroundStyle(.secondary)

            if !viewModel.customDirectories.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("自定义扫描目录:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(viewModel.customDirectories, id: \.self) { url in
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(.orange)
                            Text(url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                viewModel.removeCustomDirectory(url)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }

            HStack(spacing: 16) {
                Button("开始扫描") {
                    viewModel.scan()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("指定目录扫描") {
                    chooseDirectory()
                }
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cacheResultsView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("缓存扫描结果")
                        .font(.headline)
                    Text("共发现 \(viewModel.cacheItems.count) 项，总计 \(formattedSize(viewModel.totalSize))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    Button("全选") { viewModel.selectAll() }
                    Button("取消全选") { viewModel.deselectAll() }
                    Button("添加目录") { chooseDirectory() }
                    Button("重新扫描") { viewModel.scan() }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.blue)
            }
            .padding()

            Divider()

            List {
                ForEach(viewModel.groupedItems, id: \.0) { category, items in
                    Section {
                        ForEach(items) { item in
                            CacheRowView(item: item) {
                                viewModel.toggleItem(id: item.id)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                            Spacer()
                            Text(formattedSize(items.reduce(0) { $0 + $1.size }))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider()

            HStack {
                Text("已选择 \(viewModel.selectedItems.count) 项")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("共 \(formattedSize(viewModel.selectedSize))")
                    .font(.headline)
                Button("清除缓存") {
                    viewModel.confirmClear()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(viewModel.selectedItems.isEmpty)
            }
            .padding()
        }
    }

    private var cacheCompletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("清理完成")
                .font(.title.bold())

            if let result = viewModel.clearResult {
                VStack(spacing: 8) {
                    Text("已清除 \(result.cleared) 项")
                    Text("释放空间: \(formattedSize(result.freed))")
                        .foregroundStyle(.secondary)
                    if result.failed > 0 {
                        Text("\(result.failed) 项清除失败")
                            .foregroundStyle(.red)
                    }
                }
            }

            Button("完成") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formattedSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "选择要扫描的目录"
        panel.prompt = "扫描此目录"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.scanDirectory(url)
        }
    }
}

struct CacheRowView: View {
    let item: CacheItem
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            Image(systemName: item.category.icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .lineLimit(1)
                Text(item.displayPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(item.formattedSize)
                .foregroundStyle(.secondary)
                .font(.system(.caption, design: .monospaced))
        }
    }
}

struct CacheClearConfirmSheet: View {
    @ObservedObject var viewModel: CacheViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("确认清除缓存")
                .font(.title2.bold())

            Text("将清除 \(viewModel.selectedItems.count) 项缓存，释放 \(formattedSize(viewModel.selectedSize)) 空间")
                .foregroundStyle(.secondary)

            Text("文件将移至废纸篓，可从废纸篓恢复")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: 16) {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("确认清除") {
                    viewModel.executeClear()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(30)
        .frame(width: 380)
    }

    private func formattedSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
