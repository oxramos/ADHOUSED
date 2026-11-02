import SwiftUI

/// Responsive wrapping flow layout so tags, pills, and action badges wrap cleanly onto the next row
/// instead of truncating with "..." on narrow widths or larger Dynamic Type sizes.
public struct FlowChipLayout: Layout {
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat

    public init(horizontalSpacing: CGFloat = 6, verticalSpacing: CGFloat = 6) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        var totalHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for (index, row) in rows.enumerated() {
            if index > 0 {
                totalHeight += verticalSpacing
            }
            totalHeight += row.height
            widestRow = max(widestRow, row.width)
        }
        return CGSize(width: proposal.width ?? widestRow, height: totalHeight)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var currentY = bounds.minY

        for row in rows {
            var currentX = bounds.minX
            for item in row.items {
                let yOffset = (row.height - item.size.height) * 0.5
                item.subview.place(
                    at: CGPoint(x: currentX, y: currentY + yOffset),
                    proposal: ProposedViewSize(item.size)
                )
                currentX += item.size.width + horizontalSpacing
            }
            currentY += row.height + verticalSpacing
        }
    }

    private struct RowItem {
        let subview: LayoutSubview
        let size: CGSize
    }

    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()

        for subview in subviews {
            let idealSize = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let clampedWidth = min(idealSize.width, maxWidth)
            let itemSize = CGSize(width: clampedWidth, height: idealSize.height)

            let projectedWidth = currentRow.items.isEmpty
                ? itemSize.width
                : currentRow.width + horizontalSpacing + itemSize.width

            if !currentRow.items.isEmpty && projectedWidth > maxWidth {
                rows.append(currentRow)
                currentRow = Row()
            }

            if !currentRow.items.isEmpty {
                currentRow.width += horizontalSpacing
            }
            currentRow.items.append(RowItem(subview: subview, size: itemSize))
            currentRow.width += itemSize.width
            currentRow.height = max(currentRow.height, itemSize.height)
        }

        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }
        return rows
    }
}
