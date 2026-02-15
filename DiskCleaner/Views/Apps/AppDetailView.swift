import SwiftUI

struct AppDetailView: View {
    let app: InstalledApp
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 16) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.title2.bold())
                        if let bundleId = app.bundleIdentifier {
                            Text(bundleId)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        Text(app.bundleURL.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }

                    Spacer()

                    Button("Uninstall") {
                        appVM.uninstallerVM.requestUninstall(app)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()

                Divider()

                // Size cards
                HStack(spacing: 12) {
                    SizeCardView(
                        title: "App Bundle",
                        size: app.formattedBundleSize,
                        icon: "app.fill",
                        color: .blue
                    )
                    SizeCardView(
                        title: "Associated Data",
                        size: app.formattedAssociatedSize,
                        icon: "doc.on.doc.fill",
                        color: .orange
                    )
                    SizeCardView(
                        title: "Total",
                        size: app.formattedTotalSize,
                        icon: "sum",
                        color: .red
                    )
                }
                .padding(.horizontal)

                // Associated files by category
                if !app.associatedFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Associated Files")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(groupedFiles, id: \.0) { category, files in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    Text(category.rawValue)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(formattedSize(for: files))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }

                                ForEach(files) { file in
                                    HStack {
                                        Text(file.url.lastPathComponent)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                            .padding(.leading, 28)
                                        Spacer()
                                        Text(file.formattedSize)
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.title)
                                .foregroundStyle(.green)
                            Text("No associated data found")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                }

                Spacer()
            }
        }
    }

    private var groupedFiles: [(AssociatedFileCategory, [AssociatedFile])] {
        let grouped = Dictionary(grouping: app.associatedFiles) { $0.category }
        return AssociatedFileCategory.allCases.compactMap { category in
            guard let files = grouped[category], !files.isEmpty else { return nil }
            return (category, files)
        }
    }

    private func formattedSize(for files: [AssociatedFile]) -> String {
        let total = files.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
}

// MARK: - Size Card

struct SizeCardView: View {
    let title: String
    let size: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(size)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
