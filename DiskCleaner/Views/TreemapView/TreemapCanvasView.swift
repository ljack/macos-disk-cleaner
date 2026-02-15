import SwiftUI

struct TreemapCanvasView: View {
    let root: FileNode
    @Environment(AppViewModel.self) private var appVM
    @State private var hoveredRect: TreemapRect?
    @State private var layoutRects: [TreemapRect] = []
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let bounds = CGRect(origin: .zero, size: geo.size)

            Canvas { context, size in
                drawTreemap(context: &context, rects: layoutRects, size: size)
            }
            .onChange(of: geo.size) { _, newSize in
                canvasSize = newSize
                recalculateLayout(bounds: CGRect(origin: .zero, size: newSize))
            }
            .onAppear {
                canvasSize = geo.size
                recalculateLayout(bounds: bounds)
            }
            .onChange(of: root.id) {
                recalculateLayout(bounds: CGRect(origin: .zero, size: canvasSize))
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoveredRect = hitTest(location)
                case .ended:
                    hoveredRect = nil
                }
            }
            .onTapGesture(count: 2) { location in
                if let rect = hitTest(location) {
                    if rect.node.isDirectory {
                        appVM.zoomIntoNode(rect.node)
                    } else {
                        appVM.revealInFinder(rect.node)
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                if let hovered = hoveredRect {
                    tooltip(for: hovered)
                }
            }
        }
    }

    private func recalculateLayout(bounds: CGRect) {
        layoutRects = SquarifiedTreemap.layout(
            node: root,
            bounds: bounds.insetBy(dx: 2, dy: 2),
            maxDepth: 2,
            minSize: 16
        )
    }

    private func drawTreemap(context: inout GraphicsContext, rects: [TreemapRect], size: CGSize) {
        // Draw background
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(.black.opacity(0.05))
        )

        // Sort by depth so deeper rects draw on top
        let sorted = rects.sorted { $0.depth < $1.depth }

        for treemapRect in sorted {
            let rect = treemapRect.rect
            let isHovered = hoveredRect?.id == treemapRect.id

            // Fill
            let baseColor = treemapRect.color.color
            let opacity = 0.7 - Double(treemapRect.depth) * 0.15
            let fillColor = isHovered ? baseColor.opacity(opacity + 0.2) : baseColor.opacity(opacity)

            let path = Path(rect.insetBy(dx: 1, dy: 1))
            context.fill(path, with: .color(fillColor))

            // Border
            let borderColor: Color = isHovered ? .white : .black.opacity(0.2)
            let borderWidth: CGFloat = isHovered ? 2 : 0.5
            context.stroke(path, with: .color(borderColor), lineWidth: borderWidth)

            // Label (only if rect is large enough)
            if rect.width > 50 && rect.height > 20 && treemapRect.depth <= 1 {
                let name = treemapRect.node.name
                let textRect = rect.insetBy(dx: 4, dy: 2)

                context.drawLayer { ctx in
                    ctx.clip(to: Path(textRect))
                    let text = Text(name)
                        .font(.caption2)
                        .foregroundStyle(.white)
                    ctx.draw(text, at: CGPoint(
                        x: textRect.minX + textRect.width / 2,
                        y: textRect.minY + 10
                    ))
                }
            }
        }
    }

    private func hitTest(_ point: CGPoint) -> TreemapRect? {
        // Return deepest rect that contains the point
        layoutRects.last { $0.rect.contains(point) }
    }

    @ViewBuilder
    private func tooltip(for treemapRect: TreemapRect) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(treemapRect.node.name)
                .font(.caption.bold())
            Text(treemapRect.node.formattedSize)
                .font(.caption)
            if treemapRect.node.isDirectory {
                Text("\(treemapRect.node.descendantCount) items")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Double-click to zoom in")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Double-click to reveal in Finder")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
        .padding(8)
    }
}

// Helper to make Color accessible from FileTypeCategory in Canvas
extension FileTypeCategory {
    var nsColor: NSColor {
        NSColor(color)
    }
}
