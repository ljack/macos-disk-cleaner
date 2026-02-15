import SwiftUI

struct TreemapContainerView: View {
    let root: FileNode
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb navigation
            breadcrumbBar

            Divider()

            // Treemap canvas
            TreemapCanvasView(root: root)

            Divider()

            // Legend
            legendBar
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

    private var legendBar: some View {
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
