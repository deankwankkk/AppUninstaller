import SwiftUI

struct ScanResultsView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            scrollContent
            Divider()
            footerView
        }
    }

    private var headerView: some View {
        HStack {
            if let app = viewModel.selectedApp {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                VStack(alignment: .leading) {
                    Text(app.name).font(.headline)
                    Text(app.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 12) {
                Button("全选") { viewModel.selectAll() }
                Button("取消全选") { viewModel.deselectAll() }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.blue)
        }
        .padding()
    }

    private var scrollContent: some View {
        List {
            ForEach(viewModel.groupedResults, id: \.0) { category, items in
                Section {
                    ForEach(items) { item in
                        FileRowView(item: item) {
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
    }

    private var footerView: some View {
        HStack {
            Text("已选择 \(viewModel.selectedItems.count) 项")
                .foregroundStyle(.secondary)
            Spacer()
            Text("共 \(formattedSize(viewModel.totalSelectedSize))")
                .font(.headline)
            Button("卸载") {
                viewModel.confirmRemoval()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(viewModel.selectedItems.isEmpty)
        }
        .padding()
    }

    private func formattedSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
