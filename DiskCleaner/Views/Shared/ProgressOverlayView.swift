import SwiftUI

struct ProgressOverlayView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Scanning...")
                .font(.title3.bold())

            if let progress = appVM.scanVM.progress {
                VStack(spacing: 4) {
                    HStack(spacing: 20) {
                        Label("\(progress.filesScanned) files", systemImage: "doc")
                        Label("\(progress.directoriesScanned) directories", systemImage: "folder")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text(ByteCountFormatter.string(fromByteCount: progress.bytesScanned, countStyle: .file))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Text(progress.currentPath)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .frame(maxWidth: 400)
                }
            }

            Button("Stop") {
                appVM.stopScan()
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
