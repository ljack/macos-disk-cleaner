import SwiftUI

struct PermissionsView: View {
    @Environment(AppViewModel.self) private var appVM

    private var restrictedDirs: [FileNode] {
        appVM.scanVM.restrictedDirectories
    }

    private var pendingDirs: [FileNode] {
        restrictedDirs.filter { $0.awaitingPermission }
    }

    private var deniedDirs: [FileNode] {
        restrictedDirs.filter { $0.isPermissionDenied }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Directory Permissions")
                        .font(.headline)
                    Text("\(restrictedDirs.count) \(restrictedDirs.count == 1 ? "directory needs" : "directories need") attention")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            // Directory list
            List {
                ForEach(restrictedDirs, id: \.id) { node in
                    directoryRow(node)
                }
            }
            .listStyle(.inset)

            Divider()

            // Footer actions
            HStack {
                Spacer()
                if !pendingDirs.isEmpty {
                    Button {
                        grantAllPending()
                    } label: {
                        Label("Grant All Pending", systemImage: "shield.checkered")
                    }
                    .buttonStyle(.bordered)
                    .disabled(appVM.scanVM.isResolvingDirectory)
                }
                Button {
                    appVM.openPrivacySettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func directoryRow(_ node: FileNode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .font(.body.weight(.medium))
                Text(node.url.path)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // State indicator
            if node.awaitingPermission {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.orange.opacity(0.1), in: Capsule())

                Button("Grant Access") {
                    appVM.grantAccessToDirectory(node)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(appVM.scanVM.isResolvingDirectory)
            } else if node.isPermissionDenied {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text("Denied")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.red.opacity(0.1), in: Capsule())

                Button("Retry") {
                    appVM.retryDeniedDirectory(node)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(appVM.scanVM.isResolvingDirectory)

                Button {
                    appVM.openPrivacySettings()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Granted")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.green.opacity(0.1), in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private func grantAllPending() {
        let pending = pendingDirs
        Task {
            for node in pending {
                appVM.grantAccessToDirectory(node)
                // Wait a moment between each to avoid overlapping TCC popups
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
}
