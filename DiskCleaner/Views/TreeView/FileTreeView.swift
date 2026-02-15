import SwiftUI

struct FileTreeView: View {
    let root: FileNode
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        let visibleChildren = root.children.filter { !$0.isHidden }
        List {
            OutlineGroup(visibleChildren, children: \.optionalChildren) { node in
                FileTreeRowView(node: node)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .id(appVM.hiddenNodes.count)
    }
}

// Extension to make OutlineGroup work with optional children
extension FileNode {
    var optionalChildren: [FileNode]? {
        guard isDirectory else { return nil }
        let visible = children.filter { !$0.isHidden }
        return visible.isEmpty ? nil : visible
    }
}
