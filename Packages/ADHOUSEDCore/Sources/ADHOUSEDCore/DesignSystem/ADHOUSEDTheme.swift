import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Hex Color & Contrast Extensions

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

    func toHexString() -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(
                format: "#%02X%02X%02X",
                Int(round(max(0, min(1, r)) * 255)),
                Int(round(max(0, min(1, g)) * 255)),
                Int(round(max(0, min(1, b)) * 255))
            )
        }
        #elseif canImport(AppKit)
        if let srgb = NSColor(self).usingColorSpace(.sRGB) {
            return String(
                format: "#%02X%02X%02X",
                Int(round(max(0, min(1, srgb.redComponent)) * 255)),
                Int(round(max(0, min(1, srgb.greenComponent)) * 255)),
                Int(round(max(0, min(1, srgb.blueComponent)) * 255))
            )
        }
        #endif
        return "#5E8C71"
    }

    static func relativeLuminance(ofHex hex: String) -> Double {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    static func idealForeground(onHex hex: String) -> Color {
        relativeLuminance(ofHex: hex) > 0.44 ? Color(hex: "#121317") : .white
    }
}

// MARK: - Multi-Family Theme Token Palette + User Color Customization

public struct ADHOUSEDThemeTokens: Sendable {
    public var preset: ThemePreset
    public var isDark: Bool

    public var canvasBackground: Color
    public var canvasSecondary: Color
    public var cardSurface: Color
    public var cardElevatedSurface: Color
    public var primaryInk: Color
    public var secondaryInk: Color
    public var borderInk: Color
    public var hardShadowColor: Color

    public var accentPrimary: Color
    public var accentSecondary: Color
    public var onAccentPrimary: Color
    public var onAccentSecondary: Color

    public var freshColor: Color
    public var warmingColor: Color
    public var dueNowColor: Color
    public var urgentColor: Color

    public var cardCornerRadius: CGFloat
    public var pillCornerRadius: CGFloat
    public var cardBorderWidth: CGFloat
    public var usesHardOffsetShadow: Bool
    public var hardShadowOffset: CGFloat

    public var isTerminalHUD: Bool
    public var fontDesign: Font.Design
    public var focusGradientColors: [Color]

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
        label
    }

    // MARK: Token Resolution (Base Preset + Per-Theme User Color Overrides)

    public static func resolve(
        preset: ThemePreset,
        colorScheme: ColorScheme,
        overrides: ThemeColorOverrides? = nil
    ) -> ADHOUSEDThemeTokens {
        let effectiveOverrides = overrides ?? ADHOUSEDPreferences.shared.colorOverrides(for: preset)
        var tokens = resolveBase(preset: preset, isDark: colorScheme == .dark)
        tokens.apply(overrides: effectiveOverrides)
        return tokens
    }

    public mutating func apply(overrides: ThemeColorOverrides) {
        if let hex = overrides.canvasBackgroundHex {
            let customBg = Color(hex: hex)
            canvasBackground = customBg
            isDark = Color.relativeLuminance(ofHex: hex) < 0.35
            canvasSecondary = customBg.opacity(0.88)
        }
        if let hex = overrides.cardSurfaceHex {
            let customCard = Color(hex: hex)
            cardSurface = customCard
            cardElevatedSurface = customCard
        }
        if let hex = overrides.primaryInkHex {
            let customInk = Color(hex: hex)
            primaryInk = customInk
            secondaryInk = customInk.opacity(0.68)
        }
        if let hex = overrides.accentPrimaryHex {
            let customAccent = Color(hex: hex)
            accentPrimary = customAccent
            onAccentPrimary = Color.idealForeground(onHex: hex)
            focusGradientColors = [customAccent, accentSecondary]
        }
        if let hex = overrides.accentSecondaryHex {
            let customSec = Color(hex: hex)
            accentSecondary = customSec
            onAccentSecondary = Color.idealForeground(onHex: hex)
            focusGradientColors = [accentPrimary, customSec]
        }
        if let hex = overrides.freshColorHex {
            freshColor = Color(hex: hex)
        }
        if let hex = overrides.dueNowColorHex {
            let customDue = Color(hex: hex)
            dueNowColor = customDue
            urgentColor = customDue
        }

        switch overrides.cornerStyle {
        case .themeDefault:
            break
        case .sharpTerminal:
            cardCornerRadius = 7
            pillCornerRadius = 5
        case .crispModern:
            cardCornerRadius = 14
            pillCornerRadius = 10
        case .softRounded:
            cardCornerRadius = 24
            pillCornerRadius = 99
        }

        switch overrides.fontStyle {
        case .themeDefault:
            break
        case .cleanSans:
            fontDesign = .default
        case .softRounded:
            fontDesign = .rounded
        case .monospaced:
            fontDesign = .monospaced
        }
    }

    private static func makeTokens(
        preset: ThemePreset,
        isDark: Bool,
        bg: String,
        bgSec: String,
        card: String,
        cardElev: String,
        ink: String,
        inkSec: String,
        border: String,
        accent1: String,
        accent2: String,
        fresh: String,
        warm: String,
        due: String,
        urgent: String,
        cardRadius: CGFloat,
        pillRadius: CGFloat,
        borderWidth: CGFloat = 1.0,
        hardShadow: Bool = false,
        terminalHUD: Bool = false,
        font: Font.Design = .default,
        focusGrad: [String]? = nil
    ) -> ADHOUSEDThemeTokens {
        let gradHexes = focusGrad ?? [accent1, accent2]
        return ADHOUSEDThemeTokens(
            preset: preset,
            isDark: isDark,
            canvasBackground: Color(hex: bg),
            canvasSecondary: Color(hex: bgSec),
            cardSurface: Color(hex: card),
            cardElevatedSurface: Color(hex: cardElev),
            primaryInk: Color(hex: ink),
            secondaryInk: Color(hex: inkSec),
            borderInk: Color(hex: border),
            hardShadowColor: hardShadow
                ? Color(hex: border)
                : Color.black.opacity(isDark ? 0.32 : 0.05),
            accentPrimary: Color(hex: accent1),
            accentSecondary: Color(hex: accent2),
            onAccentPrimary: Color.idealForeground(onHex: accent1),
            onAccentSecondary: Color.idealForeground(onHex: accent2),
            freshColor: Color(hex: fresh),
            warmingColor: Color(hex: warm),
            dueNowColor: Color(hex: due),
            urgentColor: Color(hex: urgent),
            cardCornerRadius: cardRadius,
            pillCornerRadius: pillRadius,
            cardBorderWidth: borderWidth,
            usesHardOffsetShadow: hardShadow,
            hardShadowOffset: hardShadow ? 3.5 : 0,
            isTerminalHUD: terminalHUD,
            fontDesign: font,
            focusGradientColors: gradHexes.map { Color(hex: $0) }
        )
    }

    // swiftlint:disable function_body_length
    public static func resolveBase(preset: ThemePreset, isDark: Bool) -> ADHOUSEDThemeTokens {
        switch (preset, isDark) {

        // =================================================================
        // FAMILY 1: QUIET & MINIMAL · LOW STIMULATION
        // =================================================================

        // 1. Quiet Sanctuary (Warm Linen Light / Velvet Charcoal Dark)
        case (.quietSanctuary, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F5F3EE", bgSec: "#EAE6DD", card: "#FCFBF8", cardElev: "#FFFFFF",
                ink: "#262522", inkSec: "#706C64", border: "#E2DDD2",
                accent1: "#5B826B", accent2: "#82786A",
                fresh: "#5B826B", warm: "#C2955A", due: "#B86E58", urgent: "#A85448",
                cardRadius: 20, pillRadius: 12, borderWidth: 0.9, font: .rounded
            )
        case (.quietSanctuary, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#151618", bgSec: "#212327", card: "#1C1E22", cardElev: "#25282D",
                ink: "#E6E4DF", inkSec: "#96938B", border: "#2E3138",
                accent1: "#7DA88E", accent2: "#A39887",
                fresh: "#7DA88E", warm: "#D1A96E", due: "#CE856E", urgent: "#C76B5E",
                cardRadius: 20, pillRadius: 12, borderWidth: 0.9, font: .rounded
            )

        // 2. Japandi Stone & Moss
        case (.japandiMoss, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#EDE9E1", bgSec: "#E1DBD0", card: "#F7F5F0", cardElev: "#FCFBF8",
                ink: "#23211D", inkSec: "#6B655B", border: "#D5CEC0",
                accent1: "#496951", accent2: "#8A6A4F",
                fresh: "#496951", warm: "#B58742", due: "#B05D44", urgent: "#9E4238",
                cardRadius: 16, pillRadius: 10, borderWidth: 1.0, font: .default
            )
        case (.japandiMoss, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#161715", bgSec: "#232521", card: "#1D1F1B", cardElev: "#272A24",
                ink: "#E8E4DA", inkSec: "#9E998D", border: "#32352E",
                accent1: "#82A888", accent2: "#B89576",
                fresh: "#82A888", warm: "#CFA463", due: "#CE7B61", urgent: "#C46054",
                cardRadius: 16, pillRadius: 10, borderWidth: 1.0, font: .default
            )

        // 3. Nordic Daylight
        case (.nordicDaylight, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F2F5F8", bgSec: "#E4EAF0", card: "#FFFFFF", cardElev: "#F9FBFD",
                ink: "#1B2430", inkSec: "#5E6D7E", border: "#D7E0EA",
                accent1: "#446E96", accent2: "#4B8F7C",
                fresh: "#4B8F7C", warm: "#C28D38", due: "#C4624D", urgent: "#B54444",
                cardRadius: 18, pillRadius: 12, borderWidth: 1.0, font: .default
            )
        case (.nordicDaylight, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#12171E", bgSec: "#1D2530", card: "#181F28", cardElev: "#212A36",
                ink: "#E8EEF5", inkSec: "#91A0B2", border: "#2A3544",
                accent1: "#74A4D1", accent2: "#6EB8A3",
                fresh: "#6EB8A3", warm: "#DEB062", due: "#DF806A", urgent: "#D66565",
                cardRadius: 18, pillRadius: 12, borderWidth: 1.0, font: .default
            )

        // =================================================================
        // FAMILY 2: MODERN ADHD FOCUS · CALM & COZY
        // =================================================================

        // 4. Matcha & Oat
        case (.matchaOat, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F6F4EC", bgSec: "#EAE6D7", card: "#FFFDF8", cardElev: "#FFFFFF",
                ink: "#22291F", inkSec: "#646E5F", border: "#DCE0D1",
                accent1: "#5B9456", accent2: "#D97E6A",
                fresh: "#5B9456", warm: "#D69E3A", due: "#D96D55", urgent: "#C74B4B",
                cardRadius: 22, pillRadius: 14, borderWidth: 1.0, font: .rounded
            )
        case (.matchaOat, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#131813", bgSec: "#1F271F", card: "#192019", cardElev: "#232C23",
                ink: "#ECF2E8", inkSec: "#99A894", border: "#2D382D",
                accent1: "#85C27E", accent2: "#EB9683",
                fresh: "#85C27E", warm: "#E8B758", due: "#EB826A", urgent: "#E06363",
                cardRadius: 22, pillRadius: 14, borderWidth: 1.0, font: .rounded
            )

        // 5. Cozy Lo-Fi Dusk
        case (.lofiDusk, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#181622", bgSec: "#262235", card: "#201D2D", cardElev: "#2A263B",
                ink: "#EFEBF9", inkSec: "#A59EC0", border: "#36314C",
                accent1: "#A58DF5", accent2: "#F29D7E",
                fresh: "#76C8A5", warm: "#EFC070", due: "#F28B7D", urgent: "#EB6A7E",
                cardRadius: 22, pillRadius: 14, borderWidth: 1.0, font: .rounded,
                focusGrad: ["#A58DF5", "#F29D7E"]
            )
        case (.lofiDusk, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F4F1FA", bgSec: "#E7E1F4", card: "#FFFFFF", cardElev: "#FCFaff",
                ink: "#241E38", inkSec: "#685E85", border: "#DAD1EE",
                accent1: "#6F52D9", accent2: "#D96F4E",
                fresh: "#3E9674", warm: "#C98A2C", due: "#D65B4B", urgent: "#C43C54",
                cardRadius: 22, pillRadius: 14, borderWidth: 1.0, font: .rounded,
                focusGrad: ["#6F52D9", "#D96F4E"]
            )

        // 6. Oceanic Deep Teal
        case (.oceanicFocus, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#0E181E", bgSec: "#182832", card: "#132129", cardElev: "#1B2E39",
                ink: "#E6F4F7", inkSec: "#8FB0BA", border: "#243B47",
                accent1: "#3BB8B0", accent2: "#63A4E8",
                fresh: "#4CC998", warm: "#E9C46A", due: "#F07F67", urgent: "#E76F51",
                cardRadius: 20, pillRadius: 13, borderWidth: 1.0, font: .default,
                focusGrad: ["#3BB8B0", "#63A4E8"]
            )
        case (.oceanicFocus, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#EDF5F7", bgSec: "#DCEBF0", card: "#FFFFFF", cardElev: "#F7FBFC",
                ink: "#12262E", inkSec: "#506E7A", border: "#CBE0E6",
                accent1: "#1D8480", accent2: "#2E6EB0",
                fresh: "#248C66", warm: "#C48A25", due: "#D45C42", urgent: "#C24038",
                cardRadius: 20, pillRadius: 13, borderWidth: 1.0, font: .default,
                focusGrad: ["#1D8480", "#2E6EB0"]
            )

        // 7. Warm Linen Bento
        case (.warmTactileBento, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F7F2EA", bgSec: "#EFE7DB", card: "#FFFFFF", cardElev: "#FBF8F3",
                ink: "#201B17", inkSec: "#6D635B", border: "#E6DDD0",
                accent1: "#3E9B6C", accent2: "#D97736",
                fresh: "#3E9B6C", warm: "#E0942C", due: "#DC5B3E", urgent: "#C93B3B",
                cardRadius: 22, pillRadius: 14, borderWidth: 1.0
            )
        case (.warmTactileBento, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#0F0D0C", bgSec: "#1B1715", card: "#181512", cardElev: "#221E1A",
                ink: "#F6EFE7", inkSec: "#A89E93", border: "#302924",
                accent1: "#52C488", accent2: "#F09A48",
                fresh: "#52C488", warm: "#F5AE3D", due: "#F06A4D", urgent: "#F25252",
                cardRadius: 22, pillRadius: 14, borderWidth: 1.0
            )

        // 8. Tactile Studio Pop (Refined Neo-Brutalist)
        case (.chunkyNeoBrutalistPop, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#FAF8F2", bgSec: "#EEEAE0", card: "#FFFFFF", cardElev: "#FFFDF7",
                ink: "#14151A", inkSec: "#4E515E", border: "#14151A",
                accent1: "#2563EB", accent2: "#10B981",
                fresh: "#10B981", warm: "#F59E0B", due: "#F97316", urgent: "#EF4444",
                cardRadius: 15, pillRadius: 10, borderWidth: 2.0, hardShadow: true,
                focusGrad: ["#14151A", "#14151A"]
            )
        case (.chunkyNeoBrutalistPop, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#111319", bgSec: "#1B1E28", card: "#181B24", cardElev: "#222633",
                ink: "#F6F7FB", inkSec: "#A6ACBE", border: "#E2E6F0",
                accent1: "#60A5FA", accent2: "#34D399",
                fresh: "#34D399", warm: "#FBBF24", due: "#FB923C", urgent: "#F87171",
                cardRadius: 15, pillRadius: 10, borderWidth: 1.8, hardShadow: true,
                focusGrad: ["#E2E6F0", "#E2E6F0"]
            )

        // =================================================================
        // FAMILY 3: OMARCHY · SIGNATURE HYPRLAND DESKTOPS
        // =================================================================

        // 9. Omarchy Tokyo Night (Quattro)
        case (.omarchyQuattro, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#16161E", bgSec: "#24283B", card: "#1A1B26", cardElev: "#24283B",
                ink: "#C0CAF5", inkSec: "#9AA5CE", border: "#3B4261",
                accent1: "#7AA2F7", accent2: "#BB9AF7",
                fresh: "#9ECE6A", warm: "#E0AF68", due: "#FF9E64", urgent: "#F7768E",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#7DCFFF", "#7AA2F7", "#BB9AF7"]
            )
        case (.omarchyQuattro, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#E1E2E7", bgSec: "#D5D6DB", card: "#EFEFF4", cardElev: "#F8F8FC",
                ink: "#343B58", inkSec: "#565F89", border: "#B9BDCB",
                accent1: "#2E7DE9", accent2: "#7847BD",
                fresh: "#587539", warm: "#8C6C3E", due: "#B15C00", urgent: "#F52A65",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#007197", "#2E7DE9", "#7847BD"]
            )

        // 10. Omarchy Catppuccin (Mocha Dark / Latte Light)
        case (.omarchyCatppuccin, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#181825", bgSec: "#313244", card: "#1E1E2E", cardElev: "#28283D",
                ink: "#CDD6F4", inkSec: "#A6ADC8", border: "#45475A",
                accent1: "#CBA6F7", accent2: "#89B4FA",
                fresh: "#A6E3A1", warm: "#F9E2AF", due: "#FAB387", urgent: "#F38BA8",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#89DCEB", "#CBA6F7", "#F5C2E7"]
            )
        case (.omarchyCatppuccin, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#E6E9EF", bgSec: "#DCE0E8", card: "#EFF1F5", cardElev: "#F8F9FC",
                ink: "#4C4F69", inkSec: "#6C6F85", border: "#BCC0CC",
                accent1: "#8839EF", accent2: "#1E66F5",
                fresh: "#40A02B", warm: "#DF8E1D", due: "#FE640B", urgent: "#D20F39",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#1E66F5", "#8839EF", "#EA76CB"]
            )

        // 11. Omarchy Kanagawa (Wave Dark / Lotus Light)
        case (.omarchyKanagawa, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#16161D", bgSec: "#2A2A37", card: "#1F1F28", cardElev: "#2A2A37",
                ink: "#DCD7BA", inkSec: "#A6A69C", border: "#363646",
                accent1: "#7E9CD8", accent2: "#957FB8",
                fresh: "#98BB6C", warm: "#E6C384", due: "#FFA066", urgent: "#E46876",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#7FB4CA", "#7E9CD8", "#D27E99"]
            )
        case (.omarchyKanagawa, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F2ECBC", bgSec: "#E5DDB0", card: "#F9F5D7", cardElev: "#FFFDF0",
                ink: "#43436C", inkSec: "#6F6F94", border: "#C9C199",
                accent1: "#4D699B", accent2: "#624C83",
                fresh: "#6F894E", warm: "#CC6D00", due: "#E98A00", urgent: "#C84053",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#4D699B", "#624C83", "#B35B79"]
            )

        // 12. Omarchy Rosé Pine (Soho Pine Dark / Dawn Light)
        case (.omarchyRosePine, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#191724", bgSec: "#26233A", card: "#1F1D2E", cardElev: "#2A273F",
                ink: "#E0DEF4", inkSec: "#908CAA", border: "#403D52",
                accent1: "#C4A7E7", accent2: "#EBBCBA",
                fresh: "#9CCFD8", warm: "#F6C177", due: "#EA9A97", urgent: "#EB6F92",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#9CCFD8", "#C4A7E7", "#EBBCBA"]
            )
        case (.omarchyRosePine, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#FAF4ED", bgSec: "#F2E9E1", card: "#FFFAF3", cardElev: "#FFFFFF",
                ink: "#575279", inkSec: "#797593", border: "#DFDAD9",
                accent1: "#907AA9", accent2: "#D7827E",
                fresh: "#286983", warm: "#EA9D34", due: "#D7827E", urgent: "#B4637A",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#56949F", "#907AA9", "#D7827E"]
            )

        // 13. Omarchy Nord Frost
        case (.omarchyNord, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#242933", bgSec: "#3B4252", card: "#2E3440", cardElev: "#3B4252",
                ink: "#ECEFF4", inkSec: "#D8DEE9", border: "#4C566A",
                accent1: "#88C0D0", accent2: "#81A1C1",
                fresh: "#A3BE8C", warm: "#EBCB8B", due: "#D08770", urgent: "#BF616A",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#8FBCBB", "#88C0D0", "#81A1C1"]
            )
        case (.omarchyNord, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#E5E9F0", bgSec: "#D8DEE9", card: "#ECEFF4", cardElev: "#F8FAFC",
                ink: "#2E3440", inkSec: "#4C566A", border: "#C2CAD8",
                accent1: "#5E81AC", accent2: "#4C7397",
                fresh: "#4F7A42", warm: "#B88728", due: "#BF6040", urgent: "#A83B46",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#5E81AC", "#88C0D0"]
            )

        // 14. Omarchy Matte Black (Ghostty OLED)
        case (.omarchyMatteBlack, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#0B0B0D", bgSec: "#1C1C21", card: "#131316", cardElev: "#1B1B20",
                ink: "#F4F4F5", inkSec: "#A1A1AA", border: "#27272A",
                accent1: "#34D399", accent2: "#38BDF8",
                fresh: "#34D399", warm: "#FBBF24", due: "#FB923C", urgent: "#F87171",
                cardRadius: 8, pillRadius: 6, borderWidth: 1.1, terminalHUD: true, font: .monospaced,
                focusGrad: ["#34D399", "#38BDF8"]
            )
        case (.omarchyMatteBlack, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F4F4F5", bgSec: "#E4E4E7", card: "#FFFFFF", cardElev: "#FAFAFA",
                ink: "#09090B", inkSec: "#52525B", border: "#D4D4D8",
                accent1: "#18181B", accent2: "#059669",
                fresh: "#059669", warm: "#D97706", due: "#EA580C", urgent: "#DC2626",
                cardRadius: 8, pillRadius: 6, borderWidth: 1.1, terminalHUD: true, font: .monospaced,
                focusGrad: ["#18181B", "#059669"]
            )

        // 15. Omarchy Everforest
        case (.omarchyEverforest, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#1E2326", bgSec: "#2E383C", card: "#272E33", cardElev: "#323C41",
                ink: "#D3C6AA", inkSec: "#9DA9A0", border: "#414B50",
                accent1: "#A7C080", accent2: "#83C092",
                fresh: "#A7C080", warm: "#DBBC7F", due: "#E69875", urgent: "#E67E80",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#A7C080", "#83C092", "#7FBBB3"]
            )
        case (.omarchyEverforest, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F3EAD3", bgSec: "#E5DFC5", card: "#FDF6E3", cardElev: "#FFFBEF",
                ink: "#5C6A72", inkSec: "#829181", border: "#D3C6AA",
                accent1: "#8DA101", accent2: "#35A77C",
                fresh: "#8DA101", warm: "#DFA000", due: "#F57D26", urgent: "#F85552",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#8DA101", "#35A77C"]
            )

        // =================================================================
        // FAMILY 4: OMARCHY · RETRO, CYBER & TONAL
        // =================================================================

        // 16. Omarchy Gruvbox Material
        case (.omarchyGruvbox, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#1D2021", bgSec: "#32302F", card: "#282828", cardElev: "#32302F",
                ink: "#D4BE98", inkSec: "#A89984", border: "#45403D",
                accent1: "#D8A657", accent2: "#7DAEA3",
                fresh: "#A9B665", warm: "#D8A657", due: "#E78A4E", urgent: "#EA6962",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#A9B665", "#D8A657", "#E78A4E"]
            )
        case (.omarchyGruvbox, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F2E5BC", bgSec: "#E5D5AD", card: "#F9F5D7", cardElev: "#FFFBEF",
                ink: "#3C3836", inkSec: "#665C54", border: "#D5C4A1",
                accent1: "#B57614", accent2: "#427B58",
                fresh: "#689D6A", warm: "#B57614", due: "#AF3A03", urgent: "#9D0006",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#689D6A", "#B57614", "#AF3A03"]
            )

        // 17. Omarchy Cyberpunk
        case (.omarchyCyberpunk, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#12111C", bgSec: "#231E38", card: "#191628", cardElev: "#26203E",
                ink: "#F4ECFF", inkSec: "#B4A5D6", border: "#4E387E",
                accent1: "#3BF4FB", accent2: "#FF5EE2",
                fresh: "#00F5A0", warm: "#FFE64D", due: "#FF5EE2", urgent: "#FF3366",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.3, terminalHUD: true, font: .monospaced,
                focusGrad: ["#3BF4FB", "#8B5CF6", "#FF5EE2"]
            )
        case (.omarchyCyberpunk, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F2ECF9", bgSec: "#E4D8F3", card: "#FCF9FF", cardElev: "#FFFFFF",
                ink: "#1D1130", inkSec: "#644D87", border: "#C5ADE6",
                accent1: "#D6189A", accent2: "#008CA8",
                fresh: "#00996B", warm: "#C98A00", due: "#D6189A", urgent: "#E01E4F",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.3, terminalHUD: true, font: .monospaced,
                focusGrad: ["#00A8C6", "#8B5CF6", "#D6189A"]
            )

        // 18. Omarchy Mono Slate (Quattro Minimal)
        case (.quattroMinimal, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#13141C", bgSec: "#232733", card: "#1A1D26", cardElev: "#262B38",
                ink: "#E8EDF3", inkSec: "#949FB0", border: "#384050",
                accent1: "#B4C7DC", accent2: "#8497AD",
                fresh: "#A6C2B5", warm: "#C9BE9F", due: "#C4D4E6", urgent: "#D69E9E",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#B4C7DC", "#B4C7DC"]
            )
        case (.quattroMinimal, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#DCE4EC", bgSec: "#CBD6E1", card: "#EEF3F8", cardElev: "#F8FAFC",
                ink: "#1A222C", inkSec: "#505F70", border: "#ACBCCB",
                accent1: "#415468", accent2: "#5B7087",
                fresh: "#3E6B5C", warm: "#856D38", due: "#2F455C", urgent: "#963E44",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#415468", "#415468"]
            )

        // 19. Omarchy Mineral Ash
        case (.quattroAsh, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#151519", bgSec: "#27262D", card: "#1D1D23", cardElev: "#2B2A31",
                ink: "#ECE6DA", inkSec: "#A59E92", border: "#403E46",
                accent1: "#DBD1C0", accent2: "#AE9F8C",
                fresh: "#B5C4A7", warm: "#DEC99A", due: "#E6DAC6", urgent: "#DE9B8E",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#E6DEC8", "#BEB3A0"]
            )
        case (.quattroAsh, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#E8E1D1", bgSec: "#DBD1BC", card: "#F5F0E4", cardElev: "#FCF9F2",
                ink: "#262014", inkSec: "#63563E", border: "#C8B899",
                accent1: "#6E582C", accent2: "#8C723D",
                fresh: "#526E3C", warm: "#A87719", due: "#9E531B", urgent: "#A8362B",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.2, terminalHUD: true, font: .monospaced,
                focusGrad: ["#8C723D", "#6E582C"]
            )

        // 20. Omarchy Amber Phosphor
        case (.omarchyAmber, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#131210", bgSec: "#262118", card: "#1B1814", cardElev: "#29231B",
                ink: "#F7EEDB", inkSec: "#B5A282", border: "#4A3A21",
                accent1: "#E5A93C", accent2: "#FA8963",
                fresh: "#C5D457", warm: "#FAEE68", due: "#FAAE59", urgent: "#FE5228",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.25, terminalHUD: true, font: .monospaced,
                focusGrad: ["#FAEE68", "#E5A93C", "#FE6828"]
            )
        case (.omarchyAmber, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F6EED9", bgSec: "#EAE0C3", card: "#FFFDF7", cardElev: "#FFFFFF",
                ink: "#241A04", inkSec: "#695114", border: "#DAC694",
                accent1: "#B87A04", accent2: "#D95614",
                fresh: "#557D1E", warm: "#C78700", due: "#D95614", urgent: "#C92A1D",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.25, terminalHUD: true, font: .monospaced,
                focusGrad: ["#F2B705", "#D95614"]
            )

        // 21. Omarchy Solar Copper
        case (.omarchySolarFlare, false):
            return makeTokens(
                preset: preset, isDark: false,
                bg: "#F7E6D4", bgSec: "#ECD4BC", card: "#FFF8F0", cardElev: "#FFFCF8",
                ink: "#291408", inkSec: "#6E4226", border: "#DEB48E",
                accent1: "#CC5520", accent2: "#944018",
                fresh: "#4C7D22", warm: "#C47010", due: "#D94D1A", urgent: "#B82525",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.25, terminalHUD: true, font: .monospaced,
                focusGrad: ["#E8882C", "#CC5520", "#944018"]
            )
        case (.omarchySolarFlare, true):
            return makeTokens(
                preset: preset, isDark: true,
                bg: "#14100E", bgSec: "#291E18", card: "#1E1612", cardElev: "#2B201A",
                ink: "#FFF0E3", inkSec: "#C29B7E", border: "#543524",
                accent1: "#FA8428", accent2: "#FAEE68",
                fresh: "#B0D656", warm: "#FAEE68", due: "#FA6828", urgent: "#FE2D28",
                cardRadius: 10, pillRadius: 7, borderWidth: 1.25, terminalHUD: true, font: .monospaced,
                focusGrad: ["#FAEE68", "#FA8428", "#FE2D28"]
            )
        }
    }
    // swiftlint:enable function_body_length

    public func color(for stage: FreshnessStage) -> Color {
        switch stage {
        case .fresh: return freshColor
        case .warming: return warmingColor
        case .dueToday: return dueNowColor
        case .needsAttentionNow: return urgentColor
        }
    }

    public func roomAccent(for room: RoomCategory) -> Color {
        // When user customized primary accent or uses monochrome/quiet themes, blend harmoniously
        if preset == .quattroMinimal || preset == .quattroAsh || preset == .quietSanctuary {
            switch room {
            case .kitchen, .living, .general: return accentPrimary
            case .bathroom, .laundry, .bedroom: return accentSecondary
            case .petsAndPlants: return freshColor
            case .entryAndTrash: return dueNowColor
            }
        }

        switch room {
        case .kitchen: return warmingColor
        case .bathroom: return accentSecondary
        case .bedroom: return isDark ? Color(hex: "#B497E7") : Color(hex: "#7857B8")
        case .living: return accentPrimary
        case .laundry: return isDark ? Color(hex: "#73A9E6") : Color(hex: "#3E73B5")
        case .petsAndPlants: return freshColor
        case .entryAndTrash: return dueNowColor
        case .general: return accentPrimary
        }
    }
}

// MARK: - SwiftUI Environment Key

private struct ADHOUSEDThemeKey: EnvironmentKey {
    static let defaultValue = ADHOUSEDThemeTokens.resolve(preset: .quietSanctuary, colorScheme: .light)
}

public extension EnvironmentValues {
    var adhousedTheme: ADHOUSEDThemeTokens {
        get { self[ADHOUSEDThemeKey.self] }
        set { self[ADHOUSEDThemeKey.self] = newValue }
    }
}

// MARK: - Dimensional Card & Tactile Gradient Button Modifiers

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
            ? max(theme.isTerminalHUD ? 7 : 12, theme.cardCornerRadius - (theme.isTerminalHUD ? 2 : 6))
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

                    // Base card surface + subtle top-lit elevation gradient
                    shape
                        .fill(theme.cardSurface)
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(theme.isDark ? 0.045 : 0.55),
                                    Color.clear,
                                    Color.black.opacity(theme.isDark ? 0.14 : 0.015)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    if let highlightTint, !theme.usesHardOffsetShadow {
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        highlightTint.opacity(theme.isTerminalHUD ? (theme.isDark ? 0.10 : 0.06) : (theme.isDark ? 0.11 : 0.07)),
                                        highlightTint.opacity(0.015)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .overlay {
                if theme.isTerminalHUD && highlightTint != nil {
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: theme.focusGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: compact ? 1.35 : 1.65
                        )
                } else if theme.usesHardOffsetShadow {
                    shape
                        .strokeBorder(theme.borderInk, lineWidth: theme.cardBorderWidth)
                } else {
                    ZStack {
                        shape
                            .strokeBorder(
                                highlightTint != nil
                                    ? (highlightTint ?? theme.borderInk).opacity(0.48)
                                    : theme.borderInk,
                                lineWidth: theme.cardBorderWidth
                            )
                        // Subtle top-lit specular rim
                        shape
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDark ? 0.10 : 0.65),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                ),
                                lineWidth: 0.8
                            )
                    }
                }
            }
            .shadow(
                color: theme.usesHardOffsetShadow
                    ? .clear
                    : (theme.isTerminalHUD
                        ? Color.black.opacity(theme.isDark ? 0.36 : 0.06)
                        : theme.hardShadowColor),
                radius: compact ? 5 : 10,
                x: 0,
                y: compact ? 2 : 4
            )
    }
}

public extension View {
    func adhousedCard(highlightTint: Color? = nil, compact: Bool = false) -> some View {
        modifier(ThemedCardModifier(highlightTint: highlightTint, compact: compact))
    }
}

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
            .shadow(
                color: .black.opacity(foreground == .white ? 0.18 : 0.0),
                radius: 0.8,
                x: 0,
                y: 0.8
            )
            .background {
                ZStack {
                    if theme.usesHardOffsetShadow {
                        shape
                            .fill(theme.borderInk)
                            .offset(x: pressed ? 0.5 : 2.8, y: pressed ? 0.5 : 2.8)
                    }
                    shape.fill(fill.opacity(theme.isTerminalHUD && pressed ? 0.84 : 1.0))

                    // Burnished top-lit sheen (matches Omarchy Quattro 4.x Interactive States)
                    shape.fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDark ? 0.16 : 0.22),
                                Color.clear,
                                Color.black.opacity(theme.isDark ? 0.16 : 0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .overlay {
                if theme.usesHardOffsetShadow {
                    shape.strokeBorder(theme.borderInk, lineWidth: 1.8)
                } else if theme.isTerminalHUD {
                    if pressed {
                        shape.strokeBorder(
                            LinearGradient(
                                colors: theme.focusGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.6
                        )
                    } else {
                        ZStack {
                            shape.strokeBorder(theme.borderInk.opacity(0.75), lineWidth: 1.0)
                            shape.strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.28), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                        }
                    }
                } else {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDark ? 0.18 : 0.45),
                                theme.borderInk.opacity(0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.9
                    )
                }
            }
            .offset(
                x: theme.usesHardOffsetShadow && pressed ? 2.0 : 0,
                y: theme.usesHardOffsetShadow && pressed ? 2.0 : 0
            )
            .scaleEffect(!theme.usesHardOffsetShadow && pressed ? (theme.isTerminalHUD ? 0.975 : 0.96) : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: pressed)
    }
}
