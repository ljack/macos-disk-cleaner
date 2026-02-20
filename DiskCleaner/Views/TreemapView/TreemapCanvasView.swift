import SwiftUI

struct TreemapCanvasView: View {
    let root: FileNode
    @Binding var hoveredRect: TreemapRect?
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        GeometryReader { geo in
            // Observe hiddenNodes so layout recomputes when nodes are hidden
            let _ = appVM.hiddenNodes.count
            let rects = SquarifiedTreemap.layout(
                node: root,
                bounds: CGRect(origin: .zero, size: geo.size).insetBy(dx: 2, dy: 2),
                maxDepth: 2,
                minSize: 16
            )
            let selectedIDs = Set(appVM.selectedNodes.map(\.id))

            Canvas { context, size in
                drawTreemap(context: &context, rects: rects, selectedIDs: selectedIDs, size: size)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoveredRect = rects.last { $0.rect.contains(location) }
                case .ended:
                    hoveredRect = nil
                }
            }
            .onTapGesture(count: 2) { location in
                if let rect = rects.last(where: { $0.rect.contains(location) }) {
                    if rect.node.isDirectory {
                        appVM.zoomIntoNode(rect.node)
                    } else {
                        appVM.revealInFinder(rect.node)
                    }
                }
            }
            .contextMenu {
                if let hovered = hoveredRect {
                    contextMenuItems(for: hovered.node)
                }
            }
        }
    }

    private func drawTreemap(context: inout GraphicsContext, rects: [TreemapRect], selectedIDs: Set<UUID>, size: CGSize) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(.black.opacity(0.05))
        )

        let sorted = rects.sorted { $0.depth < $1.depth }

        for treemapRect in sorted {
            let rect = treemapRect.rect
            let isHovered = hoveredRect?.id == treemapRect.id
            let isSelected = selectedIDs.contains(treemapRect.node.id)

            // Fill
            let baseColor = treemapRect.color.color
            let opacity = 0.85 - Double(treemapRect.depth) * 0.10
            let fillColor = isHovered ? baseColor.opacity(min(opacity + 0.15, 1.0)) : baseColor.opacity(opacity)

            let insetRect = rect.insetBy(dx: 1, dy: 1)
            let path = Path(insetRect)
            context.fill(path, with: .color(fillColor))

            // Border
            let borderColor: Color = isHovered ? .white : .black.opacity(0.15)
            let borderWidth: CGFloat = isHovered ? 2.5 : 0.5
            context.stroke(path, with: .color(borderColor), lineWidth: borderWidth)

            // Label — offset vertically by depth so parent/child labels don't overlap
            let depthOffset = CGFloat(treemapRect.depth) * 16
            if rect.width > 50 && rect.height > (20 + depthOffset) && treemapRect.depth <= 2 {
                let name = treemapRect.node.name
                let textRect = rect.insetBy(dx: 4, dy: 2)
                let labelY = textRect.minY + 10 + depthOffset

                context.drawLayer { ctx in
                    ctx.clip(to: Path(textRect))

                    // Shadow for legibility
                    let shadow = Text(name)
                        .font(.caption2)
                        .foregroundStyle(.black.opacity(0.6))
                    ctx.draw(shadow, at: CGPoint(
                        x: textRect.minX + textRect.width / 2 + 0.5,
                        y: labelY + 0.5
                    ))

                    let text = Text(name)
                        .font(.caption2)
                        .foregroundStyle(.white)
                    ctx.draw(text, at: CGPoint(
                        x: textRect.minX + textRect.width / 2,
                        y: labelY
                    ))
                }
            }

            // Selected indicator: small red dot with checkmark
            if isSelected && insetRect.width > 14 && insetRect.height > 14 {
                let dotSize: CGFloat = 14
                let dotCenter = CGPoint(
                    x: insetRect.maxX - dotSize / 2 - 3,
                    y: insetRect.minY + dotSize / 2 + 3
                )
                let dotRect = CGRect(
                    x: dotCenter.x - dotSize / 2,
                    y: dotCenter.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(Path(ellipseIn: dotRect), with: .color(.red))

                let checkmark = Text("\u{2713}")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                context.draw(checkmark, at: dotCenter)
            }
        }
    }

    @ViewBuilder
    private func contextMenuItems(for node: FileNode) -> some View {
        if node.isDirectory {
            Button {
                appVM.zoomIntoNode(node)
            } label: {
                Label("Zoom In", systemImage: "arrow.right.circle")
            }

            Divider()
        }

        Button {
            appVM.revealInFinder(node)
        } label: {
            Label("Reveal in Finder", systemImage: "arrow.right.circle")
        }

        if let parent = node.parent {
            Button {
                appVM.revealInFinder(parent)
            } label: {
                Label("Reveal Parent in Finder", systemImage: "folder")
            }
        }

        Divider()

        if appVM.selectedNodes.contains(node) {
            Button {
                appVM.selectedNodes.remove(node)
            } label: {
                Label("Deselect", systemImage: "xmark.circle")
            }
        } else {
            Button {
                appVM.selectedNodes.insert(node)
            } label: {
                Label("Select for Deletion", systemImage: "trash.circle")
            }
        }

        Button {
            appVM.hideNode(node)
        } label: {
            Label("Hide from Results", systemImage: "eye.slash")
        }

        if node.isDirectory {
            Divider()

            Menu {
                Button("After 1 scan") {
                    appVM.addExclusionRule(for: node, remainingScans: 1)
                }
                Button("After 3 scans") {
                    appVM.addExclusionRule(for: node, remainingScans: 3)
                }
                Button("After 5 scans") {
                    appVM.addExclusionRule(for: node, remainingScans: 5)
                }
                Divider()
                Button("Manage Exclusions...") {
                    appVM.openExclusionsManager()
                }
            } label: {
                Label("Auto-Exclude Directory", systemImage: "minus.circle")
            }
        }

        if node.url.pathExtension == "app" {
            Divider()

            Button {
                appVM.uninstallerVM.requestUninstallFromTree(bundleURL: node.url)
            } label: {
                Label("Uninstall \"\(node.name)\"...", systemImage: "trash")
            }
        }
    }
}

// Helper to make Color accessible from FileTypeCategory in Canvas
extension FileTypeCategory {
    var nsColor: NSColor {
        NSColor(color)
    }
}
