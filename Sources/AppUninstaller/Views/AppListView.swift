import SwiftUI

struct AppListView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            List(viewModel.filteredApps, selection: Binding(
                get: { viewModel.selectedApp },
                set: { app in
                    if let app { viewModel.selectApp(app) }
                }
            )) { app in
                AppRowView(app: app)
                    .tag(app)
            }
            .listStyle(.sidebar)
            .searchable(text: $viewModel.searchText, prompt: "搜索应用")
        }
        .navigationTitle("已安装应用")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { viewModel.loadApps() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("刷新列表")
            }
        }
    }
}
