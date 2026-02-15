import Foundation

/// A rectangle in the treemap layout
struct TreemapRect: Identifiable {
    let id: UUID
    let node: FileNode
    let rect: CGRect
    let depth: Int
    let color: FileTypeCategory
}

/// Pure squarified treemap layout algorithm.
/// Produces near-square rectangles for better readability.
enum SquarifiedTreemap {
    /// Lay out children of a node within the given bounds.
    /// - Parameters:
    ///   - node: Parent node whose children to lay out
    ///   - bounds: Available rectangle
    ///   - maxDepth: How deep to recurse (0 = just direct children)
    ///   - currentDepth: Current recursion depth
    ///   - minSize: Minimum rect dimension to include (skip tiny rects)
    /// - Returns: Flat array of TreemapRects for rendering
    static func layout(
        node: FileNode,
        bounds: CGRect,
        maxDepth: Int = 2,
        currentDepth: Int = 0,
        minSize: CGFloat = 20
    ) -> [TreemapRect] {
        guard node.isDirectory, !node.children.isEmpty, node.size > 0 else {
            return []
        }

        let children = node.children.filter { $0.size > 0 && !$0.isHidden }
        guard !children.isEmpty else { return [] }

        let totalSize = Double(children.reduce(0) { $0 + $1.size })
        let totalArea = Double(bounds.width * bounds.height)

        // Normalize sizes to areas
        let areas = children.map { Double($0.size) / totalSize * totalArea }

        let rects = squarify(areas: areas, bounds: bounds)
        var result: [TreemapRect] = []

        for (index, childRect) in rects.enumerated() where index < children.count {
            let child = children[index]

            // Skip rects that are too small
            if childRect.width < minSize || childRect.height < minSize {
                continue
            }

            let category = child.isDirectory
                ? FileTypeCategory.directory
                : FileTypeClassifier.classify(url: child.url)

            result.append(TreemapRect(
                id: child.id,
                node: child,
                rect: childRect,
                depth: currentDepth,
                color: category
            ))

            // Recurse into directories if we haven't hit max depth
            if child.isDirectory && currentDepth < maxDepth {
                let padding: CGFloat = 2
                let innerBounds = childRect.insetBy(dx: padding, dy: padding)
                if innerBounds.width > minSize && innerBounds.height > minSize {
                    let childRects = layout(
                        node: child,
                        bounds: innerBounds,
                        maxDepth: maxDepth,
                        currentDepth: currentDepth + 1,
                        minSize: minSize
                    )
                    result.append(contentsOf: childRects)
                }
            }
        }

        return result
    }

    /// Core squarified algorithm: partition areas into rows/columns
    /// that produce the best aspect ratios
    private static func squarify(areas: [Double], bounds: CGRect) -> [CGRect] {
        guard !areas.isEmpty else { return [] }

        var remaining = areas
        var rects: [CGRect] = []
        var currentBounds = bounds

        while !remaining.isEmpty {
            let shorter = min(Double(currentBounds.width), Double(currentBounds.height))
            let isHorizontal = currentBounds.width >= currentBounds.height

            // Greedily add items to the current row as long as aspect ratio improves
            var row: [Double] = []
            var bestRatio = Double.infinity

            while !remaining.isEmpty {
                let candidate = remaining[0]
                let testRow = row + [candidate]
                let ratio = worstAspectRatio(row: testRow, shorter: shorter)

                if ratio <= bestRatio {
                    row.append(candidate)
                    remaining.removeFirst()
                    bestRatio = ratio
                } else {
                    break
                }
            }

            // Layout this row
            let rowTotal = row.reduce(0, +)
            let totalRemaining = rowTotal + remaining.reduce(0, +)
            let fraction = totalRemaining > 0 ? rowTotal / totalRemaining : 1.0

            if isHorizontal {
                let rowWidth = CGFloat(fraction) * currentBounds.width
                var y = currentBounds.minY

                for area in row {
                    let itemFraction = rowTotal > 0 ? area / rowTotal : 0
                    let height = CGFloat(itemFraction) * currentBounds.height
                    rects.append(CGRect(
                        x: currentBounds.minX,
                        y: y,
                        width: rowWidth,
                        height: height
                    ))
                    y += height
                }

                currentBounds = CGRect(
                    x: currentBounds.minX + rowWidth,
                    y: currentBounds.minY,
                    width: currentBounds.width - rowWidth,
                    height: currentBounds.height
                )
            } else {
                let rowHeight = CGFloat(fraction) * currentBounds.height
                var x = currentBounds.minX

                for area in row {
                    let itemFraction = rowTotal > 0 ? area / rowTotal : 0
                    let width = CGFloat(itemFraction) * currentBounds.width
                    rects.append(CGRect(
                        x: x,
                        y: currentBounds.minY,
                        width: width,
                        height: rowHeight
                    ))
                    x += width
                }

                currentBounds = CGRect(
                    x: currentBounds.minX,
                    y: currentBounds.minY + rowHeight,
                    width: currentBounds.width,
                    height: currentBounds.height - rowHeight
                )
            }
        }

        return rects
    }

    /// Calculate the worst (highest) aspect ratio in a row
    private static func worstAspectRatio(row: [Double], shorter: Double) -> Double {
        guard !row.isEmpty, shorter > 0 else { return .infinity }

        let rowSum = row.reduce(0, +)
        let rowLength = rowSum / shorter

        var worst: Double = 0
        for area in row {
            guard area > 0, rowLength > 0 else { continue }
            let itemWidth = area / rowLength
            let ratio = max(itemWidth / shorter, shorter / itemWidth)
            worst = max(worst, ratio)
        }

        return worst
    }
}
