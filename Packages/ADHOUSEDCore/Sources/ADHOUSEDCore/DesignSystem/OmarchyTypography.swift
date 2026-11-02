import Foundation
import SwiftUI
import CoreText
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Bundled Font Registry (Omarchy Display + JetBrains Mono)

public enum ADHOUSEDFontRegistry {
    public static let omarchyDisplayPostScript = "OmarchyFont-Regular"
    public static let jetBrainsRegular = "JetBrainsMono-Regular"
    public static let jetBrainsMedium = "JetBrainsMono-Medium"
    public static let jetBrainsSemiBold = "JetBrainsMono-SemiBold"
    public static let jetBrainsBold = "JetBrainsMono-Bold"
    public static let jetBrainsExtraBold = "JetBrainsMono-ExtraBold"

    private static let lock = NSLock()
    private nonisolated(unsafe) static var didRegister = false

    private static let fontFileNames: [String] = [
        "OmarchyDisplay",
        "JetBrainsMono-Regular",
        "JetBrainsMono-Medium",
        "JetBrainsMono-SemiBold",
        "JetBrainsMono-Bold",
        "JetBrainsMono-ExtraBold"
    ]

    public static func registerFontsIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !didRegister else { return }
        didRegister = true

        let candidateBundles: [Bundle] = [Bundle.module, Bundle.main]
        for fileName in fontFileNames {
            var registeredThisFont = false
            for bundle in candidateBundles where !registeredThisFont {
                let urls: [URL?] = [
                    bundle.url(forResource: fileName, withExtension: "ttf"),
                    bundle.url(forResource: fileName, withExtension: "ttf", subdirectory: "Fonts"),
                    bundle.url(forResource: fileName, withExtension: "ttf", subdirectory: "Resources/Fonts")
                ]
                for case let url? in urls {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                    registeredThisFont = true
                    break
                }
            }
        }
    }

    public static func isFontAvailable(_ postScriptName: String) -> Bool {
        registerFontsIfNeeded()
        #if canImport(UIKit)
        return UIFont(name: postScriptName, size: 14) != nil
        #elseif canImport(AppKit)
        return NSFont(name: postScriptName, size: 14) != nil
        #else
        return false
        #endif
    }

    /// Sanitizes arbitrary strings into printable ASCII supported by `OmarchyFont-Regular`
    /// so smart quotes, accented letters, or dashes never render missing-glyph boxes.
    public static func sanitizeForOmarchyDisplay(_ raw: String) -> String {
        let normalized = raw
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "·", with: "/")
            .replacingOccurrences(of: "•", with: "/")
            .folding(options: .diacriticInsensitive, locale: .current)

        let asciiScalars = normalized.unicodeScalars.filter { scalar in
            scalar.value >= 0x20 && scalar.value <= 0x7E
        }
        let cleaned = String(String.UnicodeScalarView(asciiScalars))
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return cleaned.isEmpty ? "CHORES" : cleaned.uppercased()
    }
}

// MARK: - Width-Normalized Cross-Theme Typography Roles

public enum ThemeTextStyle: Sendable {
    case heroDisplay
    case sectionTitle
    case cardTitle
    case subheadlineStrong
    case bodyStrong
    case body
    case pillLabel
    case captionStrong
    case caption
    case microTag
}

public extension ADHOUSEDThemeTokens {
    /// Whether hero titles should render in authentic Omarchy block-built display lettering.
    var usesOmarchyBlockLettering: Bool {
        let pref = ADHOUSEDPreferences.shared.displayLetteringStyle
        switch pref {
        case .omarchyBlock:
            return true
        case .dimensionalModern:
            return false
        case .autoTheme:
            return isTerminalHUD || preset.isOmarchyQuattroStyle
        }
    }

    /// Calibrated font resolver that normalizes character advance widths across
    /// `JetBrains Mono` (`.monospaced`), `.rounded`, and `.default` so switching themes
    /// never smooshes buttons or shifts card heights.
    func font(_ style: ThemeTextStyle) -> Font {
        ADHOUSEDFontRegistry.registerFontsIfNeeded()
        let isMono = (fontDesign == .monospaced)
        let hasJB = isMono && ADHOUSEDFontRegistry.isFontAvailable(ADHOUSEDFontRegistry.jetBrainsRegular)

        switch style {
        case .heroDisplay:
            if usesOmarchyBlockLettering && ADHOUSEDFontRegistry.isFontAvailable(ADHOUSEDFontRegistry.omarchyDisplayPostScript) {
                return .custom(ADHOUSEDFontRegistry.omarchyDisplayPostScript, size: 19.5)
            }
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsExtraBold, size: 21)
            }
            return .system(size: isMono ? 20.5 : 24, weight: .heavy, design: fontDesign)

        case .sectionTitle:
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsExtraBold, size: 15.5)
            }
            return .system(size: isMono ? 15.5 : 18.5, weight: .heavy, design: fontDesign)

        case .cardTitle:
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsBold, size: 14.2)
            }
            return .system(size: isMono ? 14.0 : 16.2, weight: .bold, design: fontDesign)

        case .subheadlineStrong:
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsBold, size: 12.6)
            }
            return .system(size: isMono ? 12.5 : 14.5, weight: .bold, design: fontDesign)

        case .bodyStrong:
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsSemiBold, size: 12.6)
            }
            return .system(size: isMono ? 12.5 : 14.5, weight: .semibold, design: fontDesign)

        case .body:
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsRegular, size: 12.5)
            }
            return .system(size: isMono ? 12.4 : 14.5, weight: .regular, design: fontDesign)

        case .pillLabel:
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsBold, size: 11.2)
            }
            return .system(size: isMono ? 11.0 : 12.5, weight: .bold, design: fontDesign)

        case .captionStrong:
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsSemiBold, size: 11.0)
            }
            return .system(size: isMono ? 10.8 : 12.0, weight: .semibold, design: fontDesign)

        case .caption:
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsRegular, size: 10.8)
            }
            return .system(size: isMono ? 10.6 : 11.8, weight: .regular, design: fontDesign)

        case .microTag:
            if hasJB {
                return .custom(ADHOUSEDFontRegistry.jetBrainsExtraBold, size: 9.5)
            }
            return .system(size: isMono ? 9.4 : 10.0, weight: .heavy, design: fontDesign)
        }
    }

    /// Calibrated tracking per role so monospaced strings stay compact while display kickers breathe.
    func tracking(for style: ThemeTextStyle) -> CGFloat {
        let isMono = (fontDesign == .monospaced)
        switch style {
        case .heroDisplay:
            return usesOmarchyBlockLettering ? 0.6 : (isMono ? -0.2 : -0.35)
        case .sectionTitle:
            return isMono ? 0.25 : -0.2
        case .cardTitle:
            return isMono ? -0.2 : -0.15
        case .subheadlineStrong, .bodyStrong, .body:
            return isMono ? -0.15 : 0
        case .pillLabel:
            return isMono ? -0.2 : 0
        case .captionStrong, .caption:
            return isMono ? -0.1 : 0
        case .microTag:
            return isMono ? 0.55 : 0.7
        }
    }

    /// Rich luminous multi-stop gradient for hero lettering so titles never look flat.
    var heroLetteringGradient: LinearGradient {
        if isTerminalHUD || usesOmarchyBlockLettering {
            if isDark {
                return LinearGradient(
                    colors: [
                        primaryInk,
                        accentPrimary,
                        focusGradientColors.last ?? accentSecondary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        primaryInk,
                        accentPrimary,
                        accentSecondary
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        } else {
            return LinearGradient(
                colors: [
                    primaryInk,
                    primaryInk.opacity(0.92),
                    accentPrimary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

public extension View {
    func themeFont(_ style: ThemeTextStyle, in theme: ADHOUSEDThemeTokens) -> some View {
        self
            .font(theme.font(style))
            .tracking(theme.tracking(for: style))
    }
}

// MARK: - Signature Omarchy Geometric Prism Emblem (Circle · Split Chevron · Diamond)

public struct OmarchyPrismEmblemView: View {
    public let primary: Color
    public let secondary: Color
    public var height: CGFloat

    public init(primary: Color, secondary: Color, height: CGFloat = 14) {
        self.primary = primary
        self.secondary = secondary
        self.height = height
    }

    public var body: some View {
        let width = height * 2.55
        Canvas { context, size in
            let h = size.height
            let r = h * 0.44
            let cy = h * 0.50

            let topBandGrad = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [
                    Color.white.opacity(0.45),
                    primary,
                    secondary
                ]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: size.width, y: h * 0.55)
            )
            let bottomBandGrad = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [
                    primary.opacity(0.88),
                    secondary.opacity(0.72)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.5),
                endPoint: CGPoint(x: size.width, y: h)
            )

            // 1. Faceted Circle (Left)
            let circleRect = CGRect(x: h * 0.06, y: cy - r, width: r * 2, height: r * 2)
            let circlePath = Path(ellipseIn: circleRect)
            context.drawLayer { layer in
                layer.clip(to: circlePath)
                layer.fill(Path(CGRect(x: circleRect.minX, y: 0, width: circleRect.width, height: cy)), with: topBandGrad)
                layer.fill(Path(CGRect(x: circleRect.minX, y: cy + 0.6, width: circleRect.width, height: cy)), with: bottomBandGrad)
            }

            // 2. Split Angled Chevron Wing (Center)
            let chevX = circleRect.maxX + h * 0.10
            let chevW = h * 0.72
            var topWing = Path()
            topWing.move(to: CGPoint(x: chevX, y: cy - r))
            topWing.addLine(to: CGPoint(x: chevX + chevW * 0.62, y: cy - r))
            topWing.addLine(to: CGPoint(x: chevX + chevW, y: cy - 0.5))
            topWing.addLine(to: CGPoint(x: chevX + chevW * 0.36, y: cy - 0.5))
            topWing.closeSubpath()
            context.fill(topWing, with: topBandGrad)

            var bottomWing = Path()
            bottomWing.move(to: CGPoint(x: chevX + chevW * 0.36, y: cy + 0.7))
            bottomWing.addLine(to: CGPoint(x: chevX + chevW, y: cy + 0.7))
            bottomWing.addLine(to: CGPoint(x: chevX + chevW * 0.62, y: cy + r))
            bottomWing.addLine(to: CGPoint(x: chevX, y: cy + r))
            bottomWing.closeSubpath()
            context.fill(bottomWing, with: bottomBandGrad)

            // 3. Faceted Diamond Prism (Right)
            let diaCenterX = chevX + chevW + h * 0.42
            var diamond = Path()
            diamond.move(to: CGPoint(x: diaCenterX, y: cy - r))
            diamond.addLine(to: CGPoint(x: diaCenterX + r * 0.92, y: cy))
            diamond.addLine(to: CGPoint(x: diaCenterX, y: cy + r))
            diamond.addLine(to: CGPoint(x: diaCenterX - r * 0.92, y: cy))
            diamond.closeSubpath()

            context.drawLayer { layer in
                layer.clip(to: diamond)
                layer.fill(Path(CGRect(x: diaCenterX - r, y: 0, width: r * 2, height: cy)), with: topBandGrad)
                layer.fill(Path(CGRect(x: diaCenterX - r, y: cy + 0.6, width: r * 2, height: cy)), with: bottomBandGrad)
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Authentic Omarchy Block-Chiseled & Dimensional Hero Header

public struct DimensionalHeroTitleView: View {
    @Environment(\.adhousedTheme) private var theme
    public let title: String
    public var subtitle: String?
    public var lineLimit: Int

    public init(title: String, subtitle: String? = nil, lineLimit: Int = 2) {
        self.title = title
        self.subtitle = subtitle
        self.lineLimit = lineLimit
    }

    public var body: some View {
        let useOmarchyBlock = theme.usesOmarchyBlockLettering &&
            ADHOUSEDFontRegistry.isFontAvailable(ADHOUSEDFontRegistry.omarchyDisplayPostScript)

        VStack(alignment: .leading, spacing: useOmarchyBlock ? 5 : 4) {
            if useOmarchyBlock {
                let displayStr = ADHOUSEDFontRegistry.sanitizeForOmarchyDisplay(title)
                ZStack(alignment: .topLeading) {
                    // Crisp chiseled extrusion shadow layer
                    Text(displayStr)
                        .font(.custom(ADHOUSEDFontRegistry.omarchyDisplayPostScript, size: 19.5))
                        .tracking(0.7)
                        .lineSpacing(3)
                        .foregroundStyle(Color.black.opacity(theme.isDark ? 0.62 : 0.16))
                        .offset(x: 1.25, y: 1.6)
                        .lineLimit(lineLimit)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)

                    // Luminous gradient face
                    Text(displayStr)
                        .font(.custom(ADHOUSEDFontRegistry.omarchyDisplayPostScript, size: 19.5))
                        .tracking(0.7)
                        .lineSpacing(3)
                        .foregroundStyle(theme.heroLetteringGradient)
                        .shadow(
                            color: theme.accentPrimary.opacity(theme.isDark ? 0.26 : 0.08),
                            radius: 6,
                            x: 0,
                            y: 2
                        )
                        .lineLimit(lineLimit)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ZStack(alignment: .topLeading) {
                    // Subtle warm/cool depth relief so non-Omarchy headers also feel tactile, never flat
                    Text(title)
                        .themeFont(.heroDisplay, in: theme)
                        .foregroundStyle(
                            theme.usesHardOffsetShadow
                                ? theme.borderInk.opacity(0.22)
                                : Color.black.opacity(theme.isDark ? 0.42 : 0.07)
                        )
                        .offset(x: 0.7, y: 1.2)
                        .lineLimit(lineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)

                    Text(title)
                        .themeFont(.heroDisplay, in: theme)
                        .foregroundStyle(theme.heroLetteringGradient)
                        .lineLimit(lineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let subtitle, !subtitle.isEmpty {
                HStack(spacing: 6) {
                    if theme.isTerminalHUD {
                        Text("//")
                            .themeFont(.microTag, in: theme)
                            .foregroundStyle(theme.accentPrimary)
                    } else {
                        Circle()
                            .fill(theme.accentPrimary)
                            .frame(width: 5.5, height: 5.5)
                    }
                    Text(subtitle)
                        .themeFont(.captionStrong, in: theme)
                        .foregroundStyle(theme.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
        }
    }
}

// MARK: - Compact Omarchy Wordmark Preview Badge (For Settings & Theme Studio)

public struct OmarchyWordmarkBadge: View {
    public let text: String
    public var fontSize: CGFloat
    public let gradientColors: [Color]
    public var isDark: Bool

    public init(
        text: String = "OMARCHY",
        fontSize: CGFloat = 11,
        gradientColors: [Color],
        isDark: Bool = true
    ) {
        self.text = text
        self.fontSize = fontSize
        self.gradientColors = gradientColors
        self.isDark = isDark
    }

    public var body: some View {
        let _ = ADHOUSEDFontRegistry.registerFontsIfNeeded()
        let sanitized = ADHOUSEDFontRegistry.sanitizeForOmarchyDisplay(text)
        let hasFont = ADHOUSEDFontRegistry.isFontAvailable(ADHOUSEDFontRegistry.omarchyDisplayPostScript)

        Text(sanitized)
            .font(
                hasFont
                    ? .custom(ADHOUSEDFontRegistry.omarchyDisplayPostScript, size: fontSize)
                    : .system(size: fontSize, weight: .black, design: .monospaced)
            )
            .tracking(0.5)
            .foregroundStyle(
                LinearGradient(
                    colors: gradientColors.isEmpty ? [.white] : gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .black.opacity(isDark ? 0.5 : 0.12), radius: 1, x: 0.8, y: 1.0)
            .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Dimensional Non-Flat Section Header Bar

public struct DimensionalSectionHeader<Trailing: View>: View {
    @Environment(\.adhousedTheme) private var theme
    public let title: String
    public var accentTint: Color?
    @ViewBuilder public var trailing: () -> Trailing

    public init(
        title: String,
        accentTint: Color? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.accentTint = accentTint
        self.trailing = trailing
    }

    public var body: some View {
        let barColor = accentTint ?? theme.accentPrimary

        HStack(alignment: .center, spacing: 8) {
            if theme.isTerminalHUD {
                Text("▸")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: theme.focusGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [barColor, theme.accentSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 16)
            }

            Text(theme.isTerminalHUD ? title.uppercased() : title)
                .themeFont(.sectionTitle, in: theme)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            theme.primaryInk,
                            theme.primaryInk.opacity(theme.isDark ? 0.86 : 0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(theme.isDark ? 0.35 : 0.04), radius: 1, x: 0, y: 1)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            trailing()
        }
    }
}
