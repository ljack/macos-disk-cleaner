import SwiftUI

struct FileTreeRowView: View {
    let node: FileNode
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        HStack(spacing: 8) {
            if node.isTrashed {
                // Trashed state: restore icon + dimmed name + restore button
                Image(systemName: "arrow.uturn.backward.circle")
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text("~\(node.name)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                        .opacity(0.4)
                }

                Spacer()

                Button("Restore") {
                    appVM.restoreNodeFromTrash(node)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Text(ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                    .frame(width: 70, alignment: .trailing)
            } else if node.awaitingPermission {
                // TCC-pending state: shield icon + grant access button
                Image(systemName: "shield.lefthalf.filled")
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 1) {
                    Text(node.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("Needs permission")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Button("Grant Access") {
                    appVM.grantAccessToDirectory(node)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                // Normal state
                Toggle(isOn: Binding(
                    get: { appVM.selectedNodes.contains(node) },
                    set: { selected in
                        if selected {
                            appVM.selectedNodes.insert(node)
                        } else {
                            appVM.selectedNodes.remove(node)
                        }
                    }
                )) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .labelsHidden()

                fileIcon
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(node.name)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if node.isDirectory && node.descendantCount > 0 {
                        Text("\(node.descendantCount) items")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                sizeBar
                    .frame(width: 80, height: 12)

                Text(node.formattedSize)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            if node.isTrashed {
                Button {
                    appVM.restoreNodeFromTrash(node)
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                }
            } else if node.isPermissionDenied {
                Button {
                    appVM.retryDeniedDirectory(node)
                } label: {
                    Label("Retry Access", systemImage: "arrow.clockwise")
                }
                Button {
                    appVM.openPrivacySettings()
                } label: {
                    Label("Open Privacy Settings", systemImage: "gear")
                }
            } else if node.url.pathExtension == "app" {
                Button {
                    appVM.uninstallerVM.requestUninstallFromTree(bundleURL: node.url)
                } label: {
                    Label("Uninstall \(node.url.deletingPathExtension().lastPathComponent)...", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private var fileIcon: some View {
        if node.isPermissionDenied {
            Image(systemName: "lock.fill")
                .foregroundStyle(.red)
        } else if node.isDirectory {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
        } else {
            let category = FileTypeClassifier.classify(url: node.url)
            Image(systemName: category.icon)
                .foregroundStyle(category.color)
        }
    }

    private var sizeBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.quaternary)
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: geo.size.width * CGFloat(node.fractionOfParent))
            }
        }
    }

    private var barColor: Color {
        let fraction = node.fractionOfParent
        if fraction > 0.5 { return .red }
        if fraction > 0.2 { return .orange }
        return .blue
    }
}
