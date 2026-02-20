import SwiftUI

struct TreemapContainerView: View {
    let root: FileNode
    @Environment(AppViewModel.self) private var appVM
    @State private var hoveredRect: TreemapRect?

    var body: some View {
        VStack(spacing: 0) {
            breadcrumbBar

            Divider()

            TreemapCanvasView(root: root, hoveredRect: $hoveredRect)

            Divider()

            bottomBar
                .animation(.easeInOut(duration: 0.15), value: hoveredRect?.id)
        }
    }

    private var breadcrumbBar: some View {
        HStack(spacing: 4) {
            if appVM.treemapRoot != nil {
                Button {
                    appVM.zoomToRoot()
                } label: {
                    Image(systemName: "house")
                }
                .buttonStyle(.plain)

                ForEach(appVM.breadcrumbs) { node in
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Button(node.name) {
                        appVM.zoomIntoNode(node)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Image(systemName: "house")
                Text(root.name)
            }

            Spacer()

            Text(root.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if let hovered = hoveredRect {
            HStack(spacing: 8) {
                Circle()
                    .fill(hovered.color.color)
                    .frame(width: 8, height: 8)

                Text(hovered.node.name)
                    .font(.caption.bold())
                    .lineLimit(1)

                Text(hovered.node.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if hovered.node.isDirectory {
                    Text("\(hovered.node.descendantCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(hovered.node.isDirectory ? "Double-click to zoom" : "Double-click to reveal")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.bar)
        } else {
            HStack(spacing: 16) {
                ForEach(FileTypeCategory.allCases, id: \.self) { category in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 8, height: 8)
                        Text(category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.bar)
        }
    }
}
