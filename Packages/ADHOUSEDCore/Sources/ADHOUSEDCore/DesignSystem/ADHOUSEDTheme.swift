import SwiftUI

// MARK: - Hex Color Extension

public extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 78, 159, 110)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}

// MARK: - Multi-Family Theme Token Palette (Originals + Omarchy Quattro OS 4.x)

public struct ADHOUSEDThemeTokens: Sendable {
    public let preset: ThemePreset
    public let isDark: Bool

    public let canvasBackground: Color
    public let canvasSecondary: Color
    public let cardSurface: Color
    public let cardElevatedSurface: Color
    public let primaryInk: Color
    public let secondaryInk: Color
    public let borderInk: Color
    public let hardShadowColor: Color

    public let accentPrimary: Color
    public let accentSecondary: Color
    public let onAccentPrimary: Color
    public let onAccentSecondary: Color

    public let freshColor: Color
    public let warmingColor: Color
    public let dueNowColor: Color
    public let urgentColor: Color

    public let cardCornerRadius: CGFloat
    public let pillCornerRadius: CGFloat
    public let cardBorderWidth: CGFloat
    public let usesHardOffsetShadow: Bool
    public let hardShadowOffset: CGFloat

    /// Omarchy Quattro OS 4.x HUD tokens (JetBrains/SF Mono alias, 8px window geometry, 45° active focus borders)
    public let isTerminalHUD: Bool
    public let fontDesign: Font.Design
    public let focusGradientColors: [Color]

    // MARK: Scheme Helpers

    public static func effectiveColorScheme(
        preset: ThemePreset,
        preference: ColorSchemePreference,
        systemColorScheme: ColorScheme
    ) -> ColorScheme {
        switch preference {
        case .signature:
            if let sigDark = preset.signatureIsDark {
                return sigDark ? .dark : .light
            }
            return systemColorScheme
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    public static func preferredColorSchemeOverride(
        preset: ThemePreset,
        preference: ColorSchemePreference
    ) -> ColorScheme? {
        switch preference {
        case .signature:
            guard let sigDark = preset.signatureIsDark else { return nil }
            return sigDark ? .dark : .light
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    public func hudTag(_ label: String) -> String {
        isTerminalHUD ? "[\(label)]" : label
    }

    // MARK: Token Resolution

    public static func resolve(preset: ThemePreset, colorScheme: ColorScheme) -> ADHOUSEDThemeTokens {
        let dark = (colorScheme == .dark)
        switch (preset, dark) {

        // -----------------------------------------------------------------
        // 1. WARM TACTILE BENTO (LIGHT & OLED DARK)
        // -----------------------------------------------------------------
        case (.warmTactileBento, false):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: false,
                canvasBackground: Color(hex: "#F7F2EA"),
                canvasSecondary: Color(hex: "#EFE7DB"),
                cardSurface: Color(hex: "#FFFFFF"),
                cardElevatedSurface: Color(hex: "#FBF8F3"),
                primaryInk: Color(hex: "#201B17"),
                secondaryInk: Color(hex: "#6D635B"),
                borderInk: Color(hex: "#E6DDD0"),
                hardShadowColor: Color.black.opacity(0.07),
                accentPrimary: Color(hex: "#3E9B6C"),
                accentSecondary: Color(hex: "#D97736"),
                onAccentPrimary: .white,
                onAccentSecondary: .white,
                freshColor: Color(hex: "#3E9B6C"),
                warmingColor: Color(hex: "#E0942C"),
                dueNowColor: Color(hex: "#DC5B3E"),
                urgentColor: Color(hex: "#C93B3B"),
                cardCornerRadius: 24,
                pillCornerRadius: 14,
                cardBorderWidth: 1.0,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: false,
                fontDesign: .default,
                focusGradientColors: [Color(hex: "#3E9B6C"), Color(hex: "#D97736")]
            )

        case (.warmTactileBento, true):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: true,
                canvasBackground: Color(hex: "#0C0A09"),
                canvasSecondary: Color(hex: "#151210"),
                cardSurface: Color(hex: "#1C1815"),
                cardElevatedSurface: Color(hex: "#26211D"),
                primaryInk: Color(hex: "#F6EFE7"),
                secondaryInk: Color(hex: "#A89E93"),
                borderInk: Color(hex: "#302924"),
                hardShadowColor: Color.black.opacity(0.45),
                accentPrimary: Color(hex: "#52C488"),
                accentSecondary: Color(hex: "#F09A48"),
                onAccentPrimary: Color(hex: "#0C0A09"),
                onAccentSecondary: Color(hex: "#0C0A09"),
                freshColor: Color(hex: "#52C488"),
                warmingColor: Color(hex: "#F5AE3D"),
                dueNowColor: Color(hex: "#F06A4D"),
                urgentColor: Color(hex: "#F25252"),
                cardCornerRadius: 24,
                pillCornerRadius: 14,
                cardBorderWidth: 1.0,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: false,
                fontDesign: .default,
                focusGradientColors: [Color(hex: "#52C488"), Color(hex: "#F09A48")]
            )

        // -----------------------------------------------------------------
        // 2. CHUNKY NEO-BRUTALIST POP (LIGHT & DARK)
        // -----------------------------------------------------------------
        case (.chunkyNeoBrutalistPop, false):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: false,
                canvasBackground: Color(hex: "#FFFDF5"),
                canvasSecondary: Color(hex: "#F4F0E1"),
                cardSurface: Color(hex: "#FFFFFF"),
                cardElevatedSurface: Color(hex: "#FFF8D6"),
                primaryInk: Color(hex: "#111216"),
                secondaryInk: Color(hex: "#454752"),
                borderInk: Color(hex: "#111216"),
                hardShadowColor: Color(hex: "#111216"),
                accentPrimary: Color(hex: "#00C97E"),
                accentSecondary: Color(hex: "#3B66FF"),
                onAccentPrimary: Color(hex: "#111216"),
                onAccentSecondary: .white,
                freshColor: Color(hex: "#00C97E"),
                warmingColor: Color(hex: "#FFB800"),
                dueNowColor: Color(hex: "#FF5A36"),
                urgentColor: Color(hex: "#FF3355"),
                cardCornerRadius: 16,
                pillCornerRadius: 10,
                cardBorderWidth: 2.5,
                usesHardOffsetShadow: true,
                hardShadowOffset: 4.0,
                isTerminalHUD: false,
                fontDesign: .default,
                focusGradientColors: [Color(hex: "#111216"), Color(hex: "#111216")]
            )

        case (.chunkyNeoBrutalistPop, true):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: true,
                canvasBackground: Color(hex: "#101117"),
                canvasSecondary: Color(hex: "#181A24"),
                cardSurface: Color(hex: "#1E202B"),
                cardElevatedSurface: Color(hex: "#272A38"),
                primaryInk: Color(hex: "#F8F7F2"),
                secondaryInk: Color(hex: "#B0B3C2"),
                borderInk: Color(hex: "#F0EFE9"),
                hardShadowColor: Color(hex: "#000000"),
                accentPrimary: Color(hex: "#00E594"),
                accentSecondary: Color(hex: "#6688FF"),
                onAccentPrimary: Color(hex: "#111216"),
                onAccentSecondary: Color(hex: "#111216"),
                freshColor: Color(hex: "#00E594"),
                warmingColor: Color(hex: "#FFD000"),
                dueNowColor: Color(hex: "#FF6B4A"),
                urgentColor: Color(hex: "#FF4769"),
                cardCornerRadius: 16,
                pillCornerRadius: 10,
                cardBorderWidth: 2.2,
                usesHardOffsetShadow: true,
                hardShadowOffset: 4.0,
                isTerminalHUD: false,
                fontDesign: .default,
                focusGradientColors: [Color(hex: "#F0EFE9"), Color(hex: "#F0EFE9")]
            )

        // -----------------------------------------------------------------
        // 3. OMARCHY QUATTRO (Reference Tokyo-Night Dark & Quattro Light)
        // -----------------------------------------------------------------
        case (.omarchyQuattro, true):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: true,
                canvasBackground: Color(hex: "#13141C"),
                canvasSecondary: Color(hex: "#24283B"),
                cardSurface: Color(hex: "#1A1B26"),
                cardElevatedSurface: Color(hex: "#292E42"),
                primaryInk: Color(hex: "#C0CAF5"),
                secondaryInk: Color(hex: "#9AA5CE"),
                borderInk: Color(hex: "#414868"),
                hardShadowColor: Color.black.opacity(0.35),
                accentPrimary: Color(hex: "#7AA2F7"),
                accentSecondary: Color(hex: "#BB9AF7"),
                onAccentPrimary: Color(hex: "#13141C"),
                onAccentSecondary: Color(hex: "#13141C"),
                freshColor: Color(hex: "#9ECE6A"),
                warmingColor: Color(hex: "#E0AF68"),
                dueNowColor: Color(hex: "#FF9E64"),
                urgentColor: Color(hex: "#F7768E"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.25,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#7DCFFF"), Color(hex: "#7AA2F7"), Color(hex: "#BB9AF7")]
            )

        case (.omarchyQuattro, false):
            // "4. QUATTRO LIGHT" from Showcase Sheet
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: false,
                canvasBackground: Color(hex: "#EAEEF5"),
                canvasSecondary: Color(hex: "#DCE3EE"),
                cardSurface: Color(hex: "#F8FAFD"),
                cardElevatedSurface: Color(hex: "#FFFFFF"),
                primaryInk: Color(hex: "#1A1F2E"),
                secondaryInk: Color(hex: "#535E78"),
                borderInk: Color(hex: "#BDC8DC"),
                hardShadowColor: Color.black.opacity(0.06),
                accentPrimary: Color(hex: "#3B66D4"),
                accentSecondary: Color(hex: "#7C4DFF"),
                onAccentPrimary: .white,
                onAccentSecondary: .white,
                freshColor: Color(hex: "#3C8A4B"),
                warmingColor: Color(hex: "#C77D1A"),
                dueNowColor: Color(hex: "#D65A28"),
                urgentColor: Color(hex: "#D1345B"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.25,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#2E8BC0"), Color(hex: "#3B66D4"), Color(hex: "#7C4DFF")]
            )

        // -----------------------------------------------------------------
        // 4. OMARCHY EVERFOREST (Woodland Dark & Botanical Sage Light)
        // -----------------------------------------------------------------
        case (.omarchyEverforest, true):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: true,
                canvasBackground: Color(hex: "#181C1E"),
                canvasSecondary: Color(hex: "#2D353B"),
                cardSurface: Color(hex: "#21272B"),
                cardElevatedSurface: Color(hex: "#2B3338"),
                primaryInk: Color(hex: "#D3C6AA"),
                secondaryInk: Color(hex: "#9DA9A0"),
                borderInk: Color(hex: "#475258"),
                hardShadowColor: Color.black.opacity(0.35),
                accentPrimary: Color(hex: "#A7C080"),
                accentSecondary: Color(hex: "#83C092"),
                onAccentPrimary: Color(hex: "#181C1E"),
                onAccentSecondary: Color(hex: "#181C1E"),
                freshColor: Color(hex: "#A7C080"),
                warmingColor: Color(hex: "#DBBC7F"),
                dueNowColor: Color(hex: "#E69875"),
                urgentColor: Color(hex: "#E67E80"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.25,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#A7C080"), Color(hex: "#83C092"), Color(hex: "#7FBBB3")]
            )

        case (.omarchyEverforest, false):
            // "2. EVERFOREST" Botanical Sage Mist from Showcase Sheet
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: false,
                canvasBackground: Color(hex: "#E2ECDC"),
                canvasSecondary: Color(hex: "#D2E0CA"),
                cardSurface: Color(hex: "#F1F7ED"),
                cardElevatedSurface: Color(hex: "#FAFDF8"),
                primaryInk: Color(hex: "#243523"),
                secondaryInk: Color(hex: "#4F664D"),
                borderInk: Color(hex: "#AEC4A6"),
                hardShadowColor: Color.black.opacity(0.06),
                accentPrimary: Color(hex: "#467840"),
                accentSecondary: Color(hex: "#357266"),
                onAccentPrimary: .white,
                onAccentSecondary: .white,
                freshColor: Color(hex: "#467840"),
                warmingColor: Color(hex: "#B87E1B"),
                dueNowColor: Color(hex: "#C95E2B"),
                urgentColor: Color(hex: "#C23B3B"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.25,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#6BA35D"), Color(hex: "#467840"), Color(hex: "#357266")]
            )

        // -----------------------------------------------------------------
        // 5. OMARCHY CYBERPUNK (Synthwave Void Dark & Cyber Vapor Light)
        // -----------------------------------------------------------------
        case (.omarchyCyberpunk, true):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: true,
                canvasBackground: Color(hex: "#13141C"),
                canvasSecondary: Color(hex: "#231D38"),
                cardSurface: Color(hex: "#191628"),
                cardElevatedSurface: Color(hex: "#272040"),
                primaryInk: Color(hex: "#F4ECFF"),
                secondaryInk: Color(hex: "#B4A5D6"),
                borderInk: Color(hex: "#553C8B"),
                hardShadowColor: Color.black.opacity(0.45),
                accentPrimary: Color(hex: "#3BF4FB"),
                accentSecondary: Color(hex: "#FF5EE2"),
                onAccentPrimary: Color(hex: "#13141C"),
                onAccentSecondary: Color(hex: "#13141C"),
                freshColor: Color(hex: "#00F5A0"),
                warmingColor: Color(hex: "#FFE64D"),
                dueNowColor: Color(hex: "#FF5EE2"),
                urgentColor: Color(hex: "#FF3366"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.35,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#3BF4FB"), Color(hex: "#8B5CF6"), Color(hex: "#FF5EE2")]
            )

        case (.omarchyCyberpunk, false):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: false,
                canvasBackground: Color(hex: "#F2ECF9"),
                canvasSecondary: Color(hex: "#E4D8F3"),
                cardSurface: Color(hex: "#FCF9FF"),
                cardElevatedSurface: Color(hex: "#FFFFFF"),
                primaryInk: Color(hex: "#1D1130"),
                secondaryInk: Color(hex: "#644D87"),
                borderInk: Color(hex: "#C5ADE6"),
                hardShadowColor: Color.black.opacity(0.07),
                accentPrimary: Color(hex: "#D6189A"),
                accentSecondary: Color(hex: "#008CA8"),
                onAccentPrimary: .white,
                onAccentSecondary: .white,
                freshColor: Color(hex: "#00996B"),
                warmingColor: Color(hex: "#C98A00"),
                dueNowColor: Color(hex: "#D6189A"),
                urgentColor: Color(hex: "#E01E4F"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.35,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#00A8C6"), Color(hex: "#8B5CF6"), Color(hex: "#D6189A")]
            )

        // -----------------------------------------------------------------
        // 6. QUATTRO MINIMAL & MIST (Zero-Saturation Slate Dark & Mist Light)
        // -----------------------------------------------------------------
        case (.quattroMinimal, true):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: true,
                canvasBackground: Color(hex: "#13141C"),
                canvasSecondary: Color(hex: "#232733"),
                cardSurface: Color(hex: "#1A1D26"),
                cardElevatedSurface: Color(hex: "#262B38"),
                primaryInk: Color(hex: "#E8EDF3"),
                secondaryInk: Color(hex: "#949FB0"),
                borderInk: Color(hex: "#384050"),
                hardShadowColor: Color.black.opacity(0.35),
                accentPrimary: Color(hex: "#B4C7DC"),
                accentSecondary: Color(hex: "#8497AD"),
                onAccentPrimary: Color(hex: "#13141C"),
                onAccentSecondary: Color(hex: "#13141C"),
                freshColor: Color(hex: "#A6C2B5"),
                warmingColor: Color(hex: "#C9BE9F"),
                dueNowColor: Color(hex: "#C4D4E6"),
                urgentColor: Color(hex: "#D69E9E"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.25,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                // Sheet 1 Rule 2: Solid Accent Focus Rings
                focusGradientColors: [Color(hex: "#B4C7DC"), Color(hex: "#B4C7DC")]
            )

        case (.quattroMinimal, false):
            // "4. QUATTRO MIST" from Sheet 1
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: false,
                canvasBackground: Color(hex: "#DCE4EC"),
                canvasSecondary: Color(hex: "#CBD6E1"),
                cardSurface: Color(hex: "#EEF3F8"),
                cardElevatedSurface: Color(hex: "#F8FAFC"),
                primaryInk: Color(hex: "#1A222C"),
                secondaryInk: Color(hex: "#505F70"),
                borderInk: Color(hex: "#ACBCCB"),
                hardShadowColor: Color.black.opacity(0.06),
                accentPrimary: Color(hex: "#415468"),
                accentSecondary: Color(hex: "#5B7087"),
                onAccentPrimary: .white,
                onAccentSecondary: .white,
                freshColor: Color(hex: "#3E6B5C"),
                warmingColor: Color(hex: "#856D38"),
                dueNowColor: Color(hex: "#2F455C"),
                urgentColor: Color(hex: "#963E44"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.25,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#415468"), Color(hex: "#415468")]
            )

        // -----------------------------------------------------------------
        // 7. QUATTRO ASH & DESERT SUN (Warm Stone Dark & Desert Sand Light)
        // -----------------------------------------------------------------
        case (.quattroAsh, true):
            // "3. QUATTRO ASH" from Sheet 1
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: true,
                canvasBackground: Color(hex: "#13141C"),
                canvasSecondary: Color(hex: "#27262D"),
                cardSurface: Color(hex: "#1C1C22"),
                cardElevatedSurface: Color(hex: "#2B2A31"),
                primaryInk: Color(hex: "#ECE6DA"),
                secondaryInk: Color(hex: "#A59E92"),
                borderInk: Color(hex: "#403E46"),
                hardShadowColor: Color.black.opacity(0.35),
                accentPrimary: Color(hex: "#DBD1C0"),
                accentSecondary: Color(hex: "#AE9F8C"),
                onAccentPrimary: Color(hex: "#141418"),
                onAccentSecondary: Color(hex: "#141418"),
                freshColor: Color(hex: "#B5C4A7"),
                warmingColor: Color(hex: "#DEC99A"),
                dueNowColor: Color(hex: "#E6DAC6"),
                urgentColor: Color(hex: "#DE9B8E"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.25,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#E6DEC8"), Color(hex: "#BEB3A0")]
            )

        case (.quattroAsh, false):
            // "3. DESERT SUN" from Sheet 2
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: false,
                canvasBackground: Color(hex: "#E5DAC0"),
                canvasSecondary: Color(hex: "#D6C7A5"),
                cardSurface: Color(hex: "#F4EDDE"),
                cardElevatedSurface: Color(hex: "#FBF8F0"),
                primaryInk: Color(hex: "#262014"),
                secondaryInk: Color(hex: "#63563E"),
                borderInk: Color(hex: "#BFA97E"),
                hardShadowColor: Color.black.opacity(0.06),
                accentPrimary: Color(hex: "#7D6024"),
                accentSecondary: Color(hex: "#997834"),
                onAccentPrimary: .white,
                onAccentSecondary: .white,
                freshColor: Color(hex: "#526E3C"),
                warmingColor: Color(hex: "#A87719"),
                dueNowColor: Color(hex: "#9E531B"),
                urgentColor: Color(hex: "#A8362B"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.25,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#9E7B2F"), Color(hex: "#694F1A")]
            )

        // -----------------------------------------------------------------
        // 8. OMARCHY AMBER WAVE & SUNFLOWER (Sheet 2 Cols 1 & 4)
        // -----------------------------------------------------------------
        case (.omarchyAmber, true):
            // "1. AMBER WAVE" from Sheet 2
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: true,
                canvasBackground: Color(hex: "#13141C"),
                canvasSecondary: Color(hex: "#27231C"),
                cardSurface: Color(hex: "#1B1918"),
                cardElevatedSurface: Color(hex: "#2A241B"),
                primaryInk: Color(hex: "#F7EEDB"),
                secondaryInk: Color(hex: "#B5A282"),
                borderInk: Color(hex: "#524124"),
                hardShadowColor: Color.black.opacity(0.40),
                accentPrimary: Color(hex: "#E5A93C"),
                accentSecondary: Color(hex: "#FA8963"),
                onAccentPrimary: Color(hex: "#171208"),
                onAccentSecondary: Color(hex: "#171208"),
                freshColor: Color(hex: "#C5D457"),
                warmingColor: Color(hex: "#FAEE68"),
                dueNowColor: Color(hex: "#FAAE59"),
                urgentColor: Color(hex: "#FE5228"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.3,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#FAEE68"), Color(hex: "#E5A93C"), Color(hex: "#FE6828")]
            )

        case (.omarchyAmber, false):
            // "4. SUNFLOWER DREAMS" from Sheet 2
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: false,
                canvasBackground: Color(hex: "#F9ECB8"),
                canvasSecondary: Color(hex: "#F1DE94"),
                cardSurface: Color(hex: "#FFFBEF"),
                cardElevatedSurface: Color(hex: "#FFFFFF"),
                primaryInk: Color(hex: "#241A04"),
                secondaryInk: Color(hex: "#695114"),
                borderInk: Color(hex: "#DBBD5C"),
                hardShadowColor: Color.black.opacity(0.06),
                accentPrimary: Color(hex: "#B87A04"),
                accentSecondary: Color(hex: "#D95614"),
                onAccentPrimary: .white,
                onAccentSecondary: .white,
                freshColor: Color(hex: "#557D1E"),
                warmingColor: Color(hex: "#C78700"),
                dueNowColor: Color(hex: "#D95614"),
                urgentColor: Color(hex: "#C92A1D"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.3,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#F2B705"), Color(hex: "#D95614")]
            )

        // -----------------------------------------------------------------
        // 9. OMARCHY SOLAR FLARE (Sheet 2 Col 2 — High-Voltage Tangerine)
        // -----------------------------------------------------------------
        case (.omarchySolarFlare, false):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: false,
                canvasBackground: Color(hex: "#FCD89D"),
                canvasSecondary: Color(hex: "#F7C474"),
                cardSurface: Color(hex: "#FFF4E0"),
                cardElevatedSurface: Color(hex: "#FFFAF0"),
                primaryInk: Color(hex: "#291003"),
                secondaryInk: Color(hex: "#6E3510"),
                borderInk: Color(hex: "#E3984B"),
                hardShadowColor: Color.black.opacity(0.07),
                accentPrimary: Color(hex: "#DE5412"),
                accentSecondary: Color(hex: "#9E3508"),
                onAccentPrimary: .white,
                onAccentSecondary: .white,
                freshColor: Color(hex: "#4C7D22"),
                warmingColor: Color(hex: "#CC7008"),
                dueNowColor: Color(hex: "#E6480F"),
                urgentColor: Color(hex: "#BA1C1C"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.35,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#FA9A28"), Color(hex: "#FE5228"), Color(hex: "#9E3508")]
            )

        case (.omarchySolarFlare, true):
            return ADHOUSEDThemeTokens(
                preset: preset,
                isDark: true,
                canvasBackground: Color(hex: "#14100E"),
                canvasSecondary: Color(hex: "#2B1D15"),
                cardSurface: Color(hex: "#1F1510"),
                cardElevatedSurface: Color(hex: "#2E1F17"),
                primaryInk: Color(hex: "#FFF0E3"),
                secondaryInk: Color(hex: "#C29B7E"),
                borderInk: Color(hex: "#5C3620"),
                hardShadowColor: Color.black.opacity(0.45),
                accentPrimary: Color(hex: "#FA8428"),
                accentSecondary: Color(hex: "#FAEE68"),
                onAccentPrimary: Color(hex: "#1A0D04"),
                onAccentSecondary: Color(hex: "#1A0D04"),
                freshColor: Color(hex: "#B0D656"),
                warmingColor: Color(hex: "#FAEE68"),
                dueNowColor: Color(hex: "#FA6828"),
                urgentColor: Color(hex: "#FE2D28"),
                cardCornerRadius: 10,
                pillCornerRadius: 7,
                cardBorderWidth: 1.35,
                usesHardOffsetShadow: false,
                hardShadowOffset: 0,
                isTerminalHUD: true,
                fontDesign: .monospaced,
                focusGradientColors: [Color(hex: "#FAEE68"), Color(hex: "#FA8428"), Color(hex: "#FE2D28")]
            )
        }
    }

    public func color(for stage: FreshnessStage) -> Color {
        switch stage {
        case .fresh: return freshColor
        case .warming: return warmingColor
        case .dueToday: return dueNowColor
        case .needsAttentionNow: return urgentColor
        }
    }

    public func roomAccent(for room: RoomCategory) -> Color {
        switch preset {
        case .warmTactileBento:
            switch room {
            case .kitchen: return Color(hex: isDark ? "#F09A48" : "#D97736")
            case .bathroom: return Color(hex: isDark ? "#59B4D1" : "#348AA7")
            case .bedroom: return Color(hex: isDark ? "#A98EDA" : "#7C5FB8")
            case .living: return Color(hex: isDark ? "#52C488" : "#3E9B6C")
            case .laundry: return Color(hex: isDark ? "#6BA3E8" : "#4378BD")
            case .petsAndPlants: return Color(hex: isDark ? "#7ACC66" : "#569E44")
            case .entryAndTrash: return Color(hex: isDark ? "#E87A64" : "#C95944")
            case .general: return accentPrimary
            }

        case .chunkyNeoBrutalistPop:
            switch room {
            case .kitchen: return Color(hex: "#FF7A2F")
            case .bathroom: return Color(hex: "#00B8D9")
            case .bedroom: return Color(hex: "#9B6BFF")
            case .living: return Color(hex: "#00C97E")
            case .laundry: return Color(hex: "#3B66FF")
            case .petsAndPlants: return Color(hex: "#65D629")
            case .entryAndTrash: return Color(hex: "#FF4D5E")
            case .general: return accentPrimary
            }

        case .omarchyQuattro:
            // Reference ANSI Spectrum from Omarchy OS Style Sheet
            switch room {
            case .kitchen: return Color(hex: isDark ? "#E0AF68" : "#C27816")
            case .bathroom: return Color(hex: isDark ? "#7DCFFF" : "#1F7EA8")
            case .bedroom: return Color(hex: isDark ? "#BB9AF7" : "#6E44C9")
            case .living: return Color(hex: isDark ? "#9ECE6A" : "#3C8A4B")
            case .laundry: return Color(hex: isDark ? "#7AA2F7" : "#3B66D4")
            case .petsAndPlants: return Color(hex: isDark ? "#73DACA" : "#248277")
            case .entryAndTrash: return Color(hex: isDark ? "#F7768E" : "#C93653")
            case .general: return accentPrimary
            }

        case .omarchyEverforest:
            switch room {
            case .kitchen: return Color(hex: isDark ? "#DBBC7F" : "#9E6D16")
            case .bathroom: return Color(hex: isDark ? "#7FBBB3" : "#2E706A")
            case .bedroom: return Color(hex: isDark ? "#D699B6" : "#8A4769")
            case .living: return Color(hex: isDark ? "#A7C080" : "#467840")
            case .laundry: return Color(hex: isDark ? "#83C092" : "#357266")
            case .petsAndPlants: return Color(hex: isDark ? "#A7C080" : "#3B6E36")
            case .entryAndTrash: return Color(hex: isDark ? "#E69875" : "#B55228")
            case .general: return accentPrimary
            }

        case .omarchyCyberpunk:
            switch room {
            case .kitchen: return Color(hex: isDark ? "#FF5EE2" : "#D6189A")
            case .bathroom: return Color(hex: isDark ? "#3BF4FB" : "#008CA8")
            case .bedroom: return Color(hex: isDark ? "#A855F7" : "#7B2CBF")
            case .living: return Color(hex: isDark ? "#00F5A0" : "#008F5D")
            case .laundry: return Color(hex: isDark ? "#60A5FA" : "#2563EB")
            case .petsAndPlants: return Color(hex: isDark ? "#2DD4BF" : "#0D9488")
            case .entryAndTrash: return Color(hex: isDark ? "#FF477E" : "#D91B5C")
            case .general: return accentPrimary
            }

        case .quattroMinimal:
            // Sheet 1 Rule 1: Zero-Saturation / Monochrome Slate Tonal Ramp
            return isDark ? Color(hex: "#B4C7DC") : Color(hex: "#415468")

        case .quattroAsh:
            // Sheet 1 & 2: Warm Mineral Ash & Desert Sun Tonal Ramp
            return isDark ? Color(hex: "#DBD1C0") : Color(hex: "#7D6024")

        case .omarchyAmber, .omarchySolarFlare:
            // Sheet 2 Rule 1 & 3: Warm Spectrum Primary Shift (Yellow -> Amber -> Solar Coral)
            switch room {
            case .kitchen: return Color(hex: isDark ? "#FAAE59" : "#D95614")
            case .bathroom: return Color(hex: isDark ? "#FAEE68" : "#B87A04")
            case .bedroom: return Color(hex: isDark ? "#F5A558" : "#A65A08")
            case .living: return Color(hex: isDark ? "#E5A93C" : "#BA6E0A")
            case .laundry: return Color(hex: isDark ? "#FAD05A" : "#9E6408")
            case .petsAndPlants: return Color(hex: isDark ? "#C9D457" : "#5B7D1A")
            case .entryAndTrash: return Color(hex: isDark ? "#FE6828" : "#C93B14")
            case .general: return accentPrimary
            }
        }
    }
}

// MARK: - SwiftUI Environment Key

private struct ADHOUSEDThemeKey: EnvironmentKey {
    static let defaultValue = ADHOUSEDThemeTokens.resolve(preset: .warmTactileBento, colorScheme: .light)
}

public extension EnvironmentValues {
    var adhousedTheme: ADHOUSEDThemeTokens {
        get { self[ADHOUSEDThemeKey.self] }
        set { self[ADHOUSEDThemeKey.self] = newValue }
    }
}

// MARK: - Card & Tactile Button Modifiers

public struct ThemedCardModifier: ViewModifier {
    @Environment(\.adhousedTheme) private var theme
    public var highlightTint: Color?
    public var compact: Bool

    public init(highlightTint: Color? = nil, compact: Bool = false) {
        self.highlightTint = highlightTint
        self.compact = compact
    }

    public func body(content: Content) -> some View {
        let radius = compact
            ? max(theme.isTerminalHUD ? 8 : 12, theme.cardCornerRadius - (theme.isTerminalHUD ? 2 : 6))
            : theme.cardCornerRadius
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        content
            .background {
                ZStack {
                    if theme.usesHardOffsetShadow {
                        shape
                            .fill(highlightTint ?? theme.hardShadowColor)
                            .offset(
                                x: compact ? 2.5 : theme.hardShadowOffset,
                                y: compact ? 2.5 : theme.hardShadowOffset
                            )
                    }
                    shape
                        .fill(theme.cardSurface)
                    if let highlightTint, !theme.usesHardOffsetShadow {
                        shape
                            .fill(highlightTint.opacity(theme.isTerminalHUD ? (theme.isDark ? 0.07 : 0.05) : (theme.isDark ? 0.10 : 0.06)))
                    }
                }
            }
            .overlay {
                if theme.isTerminalHUD && highlightTint != nil {
                    // Omarchy Quattro OS Style Sheet Section 5: 45-degree Active Focus Border Ring
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: theme.focusGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: compact ? 1.45 : 1.75
                        )
                } else {
                    shape
                        .strokeBorder(
                            highlightTint != nil && !theme.usesHardOffsetShadow
                                ? (highlightTint ?? theme.borderInk).opacity(0.45)
                                : theme.borderInk,
                            lineWidth: theme.cardBorderWidth
                        )
                }
            }
            .shadow(
                color: (theme.usesHardOffsetShadow || theme.isTerminalHUD) ? .clear : theme.hardShadowColor,
                radius: compact ? 6 : 12,
                x: 0,
                y: compact ? 3 : 6
            )
    }
}

public extension View {
    func adhousedCard(highlightTint: Color? = nil, compact: Bool = false) -> some View {
        modifier(ThemedCardModifier(highlightTint: highlightTint, compact: compact))
    }
}

/// Tactile button style adapting across:
/// - Warm Tactile Bento (plush springy elevation)
/// - Chunky Neo-Brutalist Pop (physical 4pt mechanical switch offset)
/// - Omarchy Quattro OS 4.x (crisp 8px terminal geometry, fill-alpha press & 45° active focus ring)
public struct TactileActionButtonStyle: ButtonStyle {
    @Environment(\.adhousedTheme) private var theme
    public var fill: Color
    public var foreground: Color
    public var cornerRadius: CGFloat?

    public init(fill: Color, foreground: Color = .white, cornerRadius: CGFloat? = nil) {
        self.fill = fill
        self.foreground = foreground
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        let radius = cornerRadius ?? theme.pillCornerRadius
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let pressed = configuration.isPressed

        configuration.label
            .foregroundStyle(foreground)
            .background {
                ZStack {
                    if theme.usesHardOffsetShadow {
                        shape
                            .fill(theme.borderInk)
                            .offset(x: pressed ? 0.5 : 3.0, y: pressed ? 0.5 : 3.0)
                    }
                    shape.fill(fill.opacity(theme.isTerminalHUD && pressed ? 0.82 : 1.0))
                }
            }
            .overlay {
                if theme.usesHardOffsetShadow {
                    shape.strokeBorder(theme.borderInk, lineWidth: 2.0)
                } else if theme.isTerminalHUD {
                    if pressed {
                        shape.strokeBorder(
                            LinearGradient(
                                colors: theme.focusGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.75
                        )
                    } else {
                        shape.strokeBorder(theme.borderInk.opacity(0.85), lineWidth: 1.0)
                    }
                }
            }
            .offset(
                x: theme.usesHardOffsetShadow && pressed ? 2.5 : 0,
                y: theme.usesHardOffsetShadow && pressed ? 2.5 : 0
            )
            .scaleEffect(!theme.usesHardOffsetShadow && pressed ? (theme.isTerminalHUD ? 0.975 : 0.95) : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.68), value: pressed)
    }
}
