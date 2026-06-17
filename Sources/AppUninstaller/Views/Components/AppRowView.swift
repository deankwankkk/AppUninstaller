import SwiftUI

struct AppRowView: View {
    let app: AppInfo

    var body: some View {
        HStack(spacing: 10) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: "app")
                    .font(.title2)
                    .frame(width: 28, height: 28)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .lineLimit(1)
                Text(app.version ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct FileRowView: View {
    let item: ScanResult
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

            Text(item.displayPath)
                .lineLimit(1)
                .truncationMode(.middle)
                .font(.system(.body, design: .monospaced))

            Spacer()

            Text(item.formattedSize)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}
