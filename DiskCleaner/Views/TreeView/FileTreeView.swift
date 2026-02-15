import SwiftUI

struct FileTreeView: View {
    let root: FileNode
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        List {
            OutlineGroup(root.children, children: \.optionalChildren) { node in
                FileTreeRowView(node: node)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}

// Extension to make OutlineGroup work with optional children
extension FileNode {
    var optionalChildren: [FileNode]? {
        isDirectory && !children.isEmpty ? children : nil
    }
}
