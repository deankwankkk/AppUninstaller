import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.app")
                .font(.system(size: 64))
                .foregroundStyle(isTargeted ? .blue : .secondary)

            Text("拖放应用到此处")
                .font(.title2.bold())

            Text("或从左侧列表选择要卸载的应用")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [10])
                )
                .foregroundStyle(isTargeted ? Color.blue : Color.gray.opacity(0.3))
                .padding(20)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url {
                    DispatchQueue.main.async {
                        viewModel.handleDrop(url: url)
                    }
                }
            }
            return true
        }
    }
}
