import SwiftUI

// MARK: - Visual Time-Blindness Gauges (Spotlight Bar & Stream Battery Cell)

public struct CompactFreshnessBar: View {
    @Environment(\.adhousedTheme) private var theme
    public let snapshot: TaskFreshnessSnapshot
    public var height: CGFloat

    public init(snapshot: TaskFreshnessSnapshot, height: CGFloat = 9) {
        self.snapshot = snapshot
        self.height = height
    }

    public var body: some View {
        let barColor = theme.color(for: snapshot.stage)
        let visibleFill = max(0.08, min(1.0, snapshot.batteryFill))
        let radius = theme.isTerminalHUD ? 3.0 : height / 2.0

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(theme.canvasSecondary)
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(barColor)
                    .frame(width: max(height * 1.4, geo.size.width * visibleFill))
            }
            .overlay {
                if theme.usesHardOffsetShadow {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(theme.borderInk.opacity(0.85), lineWidth: 1.5)
                } else if theme.isTerminalHUD {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(theme.borderInk.opacity(0.75), lineWidth: 1.0)
                }
            }
        }
        .frame(height: height)
        .accessibilityLabel("Freshness \(Int(snapshot.batteryFill * 100)) percent, \(snapshot.stage.label)")
    }
}

/// Prominent multi-cell battery gauge engineered for the "Freshness Battery Stream" usability mode.
public struct LargeBatteryCellGauge: View {
    @Environment(\.adhousedTheme) private var theme
    public let snapshot: TaskFreshnessSnapshot
    public let segmentCount: Int = 5

    public init(snapshot: TaskFreshnessSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        let activeColor = theme.color(for: snapshot.stage)
        let activeCells = snapshot.isActionableToday
            ? (snapshot.stage == .needsAttentionNow ? 0 : 1)
            : max(1, Int(round(snapshot.batteryFill * Double(segmentCount))))

        HStack(spacing: 4) {
            HStack(spacing: 3) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    let isLit = index < activeCells
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            isLit
                                ? activeColor
                                : (snapshot.stage == .needsAttentionNow && index == 0
                                    ? activeColor.opacity(0.35)
                                    : theme.canvasSecondary)
                        )
                        .frame(width: 11, height: 22)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(theme.cardElevatedSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(
                        snapshot.isActionableToday ? activeColor : theme.borderInk,
                        lineWidth: theme.usesHardOffsetShadow ? 2.0 : 1.4
                    )
            )

            // Battery positive terminal nub
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(snapshot.isActionableToday ? activeColor : theme.borderInk)
                .frame(width: 3.5, height: 10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Battery \(Int(snapshot.batteryFill * 100)) percent, \(snapshot.stage.label)")
    }
}
