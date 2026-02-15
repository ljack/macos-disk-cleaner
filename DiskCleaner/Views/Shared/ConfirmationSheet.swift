import SwiftUI

struct ConfirmationSheet: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)

            Text("Move to Trash?")
                .font(.title2.bold())

            Text("The following \(appVM.selectedNodes.count) items will be moved to Trash.")
                .foregroundStyle(.secondary)

            // Items list
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(appVM.selectedNodes).sorted(by: { $0.size > $1.size })) { node in
                        HStack {
                            Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                            Text(node.name)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Text(node.formattedSize)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: 200)
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))

            // Total size
            HStack {
                Text("Total:")
                    .font(.callout.bold())
                Spacer()
                Text(totalSize)
                    .font(.callout.bold().monospacedDigit())
            }
            .padding(.horizontal)

            if let error = appVM.deletionError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Buttons
            HStack {
                Button("Cancel") {
                    appVM.showingDeleteConfirmation = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Move to Trash") {
                    appVM.performDeletion()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(appVM.isDeleting)
            }
        }
        .padding(24)
        .frame(width: 450)
    }

    private var totalSize: String {
        let total = appVM.selectedNodes.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
}
