import SwiftUI

struct FileTreeRowView: View {
    let node: FileNode
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        HStack(spacing: 8) {
            // Selection checkbox
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

            // File icon
            fileIcon
                .frame(width: 16, height: 16)

            // Name
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

            // Size bar
            sizeBar
                .frame(width: 80, height: 12)

            // Size label
            Text(node.formattedSize)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 2)
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
