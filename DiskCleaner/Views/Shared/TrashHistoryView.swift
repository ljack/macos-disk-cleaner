import SwiftUI

struct TrashHistoryView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading) {
                    Text("Trash History")
                        .font(.title3.bold())
                    Text("\(appVM.trashHistory.count) items trashed by DiskCleaner")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !appVM.trashHistory.isEmpty {
                    Button("Clear History") {
                        appVM.clearTrashHistory()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding()

            Divider()

            if appVM.trashHistory.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "trash.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("No items trashed yet")
                        .foregroundStyle(.secondary)
                    Text("Items you delete through DiskCleaner will appear here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(appVM.trashHistory) { item in
                        TrashHistoryRowView(item: item)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

struct TrashHistoryRowView: View {
    let item: TrashedItem
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: sourceIcon)
                .foregroundStyle(sourceColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .lineLimit(1)
                Text(item.originalURL.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
                HStack(spacing: 8) {
                    Text(item.source.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.fill.tertiary, in: Capsule())
                    Text(item.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(item.formattedSize)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                appVM.selectedSidebarItem = .disk
                appVM.viewMode = .list
            } label: {
                Image(systemName: "arrow.right.circle")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help("Show in Tree")

            if item.existsInTrash {
                Button("Restore") {
                    appVM.restoreFromTrash(item)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Text("Emptied")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var sourceIcon: String {
        switch item.source {
        case .fileTree: return "doc"
        case .suggestion: return "lightbulb"
        case .appUninstall: return "app"
        }
    }

    private var sourceColor: Color {
        switch item.source {
        case .fileTree: return .blue
        case .suggestion: return .green
        case .appUninstall: return .orange
        }
    }
}
