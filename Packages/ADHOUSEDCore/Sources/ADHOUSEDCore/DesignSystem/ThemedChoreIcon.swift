import SwiftUI

// MARK: - Multi-Pack Icon Catalog & Bespoke Omarchy Pixel-Art / HUD Icon Renderer

public struct ChoreIconChoice: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let pack: ChoreIconPack

    public init(id: String, label: String, pack: ChoreIconPack) {
        self.id = id
        self.label = label
        self.pack = pack
    }
}

public enum ChoreIconPack: String, CaseIterable, Identifiable, Sendable {
    case omarchyPixel
    case homeAndRooms
    case petsPlantsOutdoor
    case techLifeSelfCare
    case expressiveEmoji

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .omarchyPixel: return "Omarchy Pixel & HUD"
        case .homeAndRooms: return "Home & Cleaning"
        case .petsPlantsOutdoor: return "Pets, Plants & Outdoors"
        case .techLifeSelfCare: return "Desk, Self-Care & Life"
        case .expressiveEmoji: return "Expressive Emoji"
        }
    }
}

public enum ChoreIconCatalog {
    public static let allChoices: [ChoreIconChoice] = [
        // 1. Bespoke Omarchy Pixel-Art & Terminal HUD Glyphs
        .init(id: "omarchy:spark", label: "Sparkle", pack: .omarchyPixel),
        .init(id: "omarchy:dishes", label: "Dishes", pack: .omarchyPixel),
        .init(id: "omarchy:mug", label: "Coffee Mug", pack: .omarchyPixel),
        .init(id: "omarchy:fridge", label: "Fridge", pack: .omarchyPixel),
        .init(id: "omarchy:trash", label: "Trash Bin", pack: .omarchyPixel),
        .init(id: "omarchy:droplet", label: "Bath / Water", pack: .omarchyPixel),
        .init(id: "omarchy:shower", label: "Shower", pack: .omarchyPixel),
        .init(id: "omarchy:bed", label: "Bed & Rest", pack: .omarchyPixel),
        .init(id: "omarchy:sofa", label: "Living Sofa", pack: .omarchyPixel),
        .init(id: "omarchy:washer", label: "Washer", pack: .omarchyPixel),
        .init(id: "omarchy:hanger", label: "Clothes", pack: .omarchyPixel),
        .init(id: "omarchy:broom", label: "Sweep / Mop", pack: .omarchyPixel),
        .init(id: "omarchy:plant", label: "Bonsai / Plant", pack: .omarchyPixel),
        .init(id: "omarchy:cat", label: "Pixel Cat", pack: .omarchyPixel),
        .init(id: "omarchy:dog", label: "Pixel Dog", pack: .omarchyPixel),
        .init(id: "omarchy:paw", label: "Pet Paw", pack: .omarchyPixel),
        .init(id: "omarchy:desk", label: "Workstation", pack: .omarchyPixel),
        .init(id: "omarchy:terminal", label: "Terminal >_", pack: .omarchyPixel),
        .init(id: "omarchy:ghost", label: "Ghostty", pack: .omarchyPixel),
        .init(id: "omarchy:arch", label: "Omarchy Peak", pack: .omarchyPixel),
        .init(id: "omarchy:wave", label: "Kanagawa Wave", pack: .omarchyPixel),
        .init(id: "omarchy:pill", label: "Meds / Capsule", pack: .omarchyPixel),
        .init(id: "omarchy:cart", label: "Groceries", pack: .omarchyPixel),
        .init(id: "omarchy:mail", label: "Mail / Bills", pack: .omarchyPixel),
        .init(id: "omarchy:bolt", label: "Quick Zap", pack: .omarchyPixel),
        .init(id: "omarchy:heart", label: "8-Bit Heart", pack: .omarchyPixel),
        .init(id: "omarchy:terminal_home", label: "Home Node", pack: .omarchyPixel),

        // 2. Home & Cleaning SF Symbols
        .init(id: "sparkles", label: "Sparkles", pack: .homeAndRooms),
        .init(id: "dishwasher.fill", label: "Dishwasher", pack: .homeAndRooms),
        .init(id: "sink.fill", label: "Sink", pack: .homeAndRooms),
        .init(id: "refrigerator.fill", label: "Fridge", pack: .homeAndRooms),
        .init(id: "fork.knife", label: "Kitchen", pack: .homeAndRooms),
        .init(id: "cup.and.saucer.fill", label: "Coffee / Tea", pack: .homeAndRooms),
        .init(id: "mug.fill", label: "Mug", pack: .homeAndRooms),
        .init(id: "frying.pan.fill", label: "Cooking", pack: .homeAndRooms),
        .init(id: "waterbottle.fill", label: "Water Bottle", pack: .homeAndRooms),
        .init(id: "shower.fill", label: "Shower", pack: .homeAndRooms),
        .init(id: "bathtub.fill", label: "Bathtub", pack: .homeAndRooms),
        .init(id: "toilet.fill", label: "Toilet", pack: .homeAndRooms),
        .init(id: "bed.double.fill", label: "Bedsheets", pack: .homeAndRooms),
        .init(id: "sofa.fill", label: "Couch / Living", pack: .homeAndRooms),
        .init(id: "lamp.floor.fill", label: "Lamp", pack: .homeAndRooms),
        .init(id: "washer.fill", label: "Washer", pack: .homeAndRooms),
        .init(id: "dryer.fill", label: "Dryer", pack: .homeAndRooms),
        .init(id: "tshirt.fill", label: "Laundry", pack: .homeAndRooms),
        .init(id: "hanger", label: "Closet", pack: .homeAndRooms),
        .init(id: "cabinet.fill", label: "Dresser", pack: .homeAndRooms),
        .init(id: "fanblades.fill", label: "Vacuum / Air", pack: .homeAndRooms),
        .init(id: "drop.triangle.fill", label: "Mop Floors", pack: .homeAndRooms),
        .init(id: "trash.fill", label: "Trash", pack: .homeAndRooms),
        .init(id: "arrow.up.bin.fill", label: "Curb Bins", pack: .homeAndRooms),

        // 3. Pets, Plants & Outdoors
        .init(id: "leaf.fill", label: "Plants", pack: .petsPlantsOutdoor),
        .init(id: "camera.macro", label: "Flowers", pack: .petsPlantsOutdoor),
        .init(id: "tree.fill", label: "Garden / Yard", pack: .petsPlantsOutdoor),
        .init(id: "pawprint.fill", label: "Pet Care", pack: .petsPlantsOutdoor),
        .init(id: "cat.fill", label: "Cat", pack: .petsPlantsOutdoor),
        .init(id: "dog.fill", label: "Dog", pack: .petsPlantsOutdoor),
        .init(id: "tray.full.fill", label: "Litter Box", pack: .petsPlantsOutdoor),
        .init(id: "fish.fill", label: "Aquarium", pack: .petsPlantsOutdoor),
        .init(id: "bird.fill", label: "Bird", pack: .petsPlantsOutdoor),
        .init(id: "car.fill", label: "Car", pack: .petsPlantsOutdoor),
        .init(id: "bicycle", label: "Bike", pack: .petsPlantsOutdoor),
        .init(id: "sun.max.fill", label: "Daylight", pack: .petsPlantsOutdoor),

        // 4. Desk, Self-Care & Life Admin
        .init(id: "desktopcomputer", label: "Desk / PC", pack: .techLifeSelfCare),
        .init(id: "laptopcomputer", label: "Laptop", pack: .techLifeSelfCare),
        .init(id: "keyboard.fill", label: "Keyboard", pack: .techLifeSelfCare),
        .init(id: "gamecontroller.fill", label: "Gaming Setup", pack: .techLifeSelfCare),
        .init(id: "pills.fill", label: "Vitamins / Meds", pack: .techLifeSelfCare),
        .init(id: "heart.fill", label: "Self-Care", pack: .techLifeSelfCare),
        .init(id: "dumbbell.fill", label: "Movement", pack: .techLifeSelfCare),
        .init(id: "cart.fill", label: "Groceries", pack: .techLifeSelfCare),
        .init(id: "creditcard.fill", label: "Bills / Admin", pack: .techLifeSelfCare),
        .init(id: "envelope.open.fill", label: "Mail", pack: .techLifeSelfCare),
        .init(id: "backpack.fill", label: "Bag Reset", pack: .techLifeSelfCare),
        .init(id: "book.fill", label: "Reading / Study", pack: .techLifeSelfCare),

        // 5. Expressive Emoji Icons
        .init(id: "emoji:🧹", label: "Broom", pack: .expressiveEmoji),
        .init(id: "emoji:🧺", label: "Laundry", pack: .expressiveEmoji),
        .init(id: "emoji:🍽️", label: "Dishes", pack: .expressiveEmoji),
        .init(id: "emoji:🧽", label: "Sponge", pack: .expressiveEmoji),
        .init(id: "emoji:🫧", label: "Bubbles", pack: .expressiveEmoji),
        .init(id: "emoji:🪴", label: "Potted Plant", pack: .expressiveEmoji),
        .init(id: "emoji:🐈‍⬛", label: "Black Cat", pack: .expressiveEmoji),
        .init(id: "emoji:🐕", label: "Dog", pack: .expressiveEmoji),
        .init(id: "emoji:🛏️", label: "Bed", pack: .expressiveEmoji),
        .init(id: "emoji:🛋️", label: "Couch", pack: .expressiveEmoji),
        .init(id: "emoji:☕", label: "Coffee", pack: .expressiveEmoji),
        .init(id: "emoji:🗑️", label: "Trash", pack: .expressiveEmoji),
        .init(id: "emoji:🛒", label: "Groceries", pack: .expressiveEmoji),
        .init(id: "emoji:💊", label: "Meds", pack: .expressiveEmoji),
        .init(id: "emoji:💻", label: "Laptop", pack: .expressiveEmoji),
        .init(id: "emoji:🧘", label: "Calm", pack: .expressiveEmoji)
    ]

    public static func choices(for pack: ChoreIconPack) -> [ChoreIconChoice] {
        allChoices.filter { $0.pack == pack }
    }

    /// Maps standard SF Symbols automatically to bespoke Omarchy 11×11 pixel glyphs when Omarchy icon mode is active!
    public static func mappedOmarchyGlyphKey(for symbol: String) -> String? {
        if symbol.hasPrefix("omarchy:") {
            return String(symbol.dropFirst("omarchy:".count))
        }
        switch symbol {
        case "dishwasher.fill", "fork.knife", "sink.fill", "frying.pan.fill":
            return "dishes"
        case "cup.and.saucer.fill", "mug.fill", "waterbottle.fill":
            return "mug"
        case "refrigerator.fill":
            return "fridge"
        case "trash.fill", "arrow.up.bin.fill":
            return "trash"
        case "shower.fill", "bathtub.fill":
            return "shower"
        case "toilet.fill", "drop.fill", "spigot.fill":
            return "droplet"
        case "bed.double.fill", "moon.stars.fill":
            return "bed"
        case "sofa.fill", "lamp.floor.fill":
            return "sofa"
        case "washer.fill", "dryer.fill":
            return "washer"
        case "tshirt.fill", "hanger", "cabinet.fill":
            return "hanger"
        case "fanblades.fill", "drop.triangle.fill", "wind":
            return "broom"
        case "leaf.fill", "camera.macro", "tree.fill":
            return "plant"
        case "cat.fill", "tray.full.fill":
            return "cat"
        case "dog.fill":
            return "dog"
        case "pawprint.fill", "comb.fill", "fish.fill", "bird.fill":
            return "paw"
        case "desktopcomputer", "laptopcomputer", "keyboard.fill", "gamecontroller.fill":
            return "desk"
        case "pills.fill":
            return "pill"
        case "cart.fill", "backpack.fill":
            return "cart"
        case "envelope.open.fill", "envelope.fill", "creditcard.fill":
            return "mail"
        case "bolt.fill":
            return "bolt"
        case "heart.fill", "heart.text.square.fill":
            return "heart"
        case "house.fill":
            return "terminal_home"
        case "sparkles", "sparkles.rectangle.stack.fill", "aqi.medium":
            return "spark"
        default:
            return nil
        }
    }

    /// Fallback SF Symbol for compact Lock Screen / Dynamic Island contexts where only system symbols fit.
    public static func fallbackSystemSymbol(for iconString: String) -> String {
        if iconString.hasPrefix("omarchy:") {
            let key = String(iconString.dropFirst("omarchy:".count))
            switch key {
            case "dishes": return "dishwasher.fill"
            case "mug": return "mug.fill"
            case "fridge": return "refrigerator.fill"
            case "trash": return "trash.fill"
            case "droplet": return "drop.fill"
            case "shower": return "shower.fill"
            case "bed": return "bed.double.fill"
            case "sofa": return "sofa.fill"
            case "washer": return "washer.fill"
            case "hanger": return "hanger"
            case "broom": return "sparkles"
            case "plant": return "leaf.fill"
            case "cat": return "cat.fill"
            case "dog": return "dog.fill"
            case "paw": return "pawprint.fill"
            case "desk": return "desktopcomputer"
            case "terminal", "ghost", "arch": return "terminal.fill"
            case "wave": return "water.waves"
            case "pill": return "pills.fill"
            case "cart": return "cart.fill"
            case "mail": return "envelope.fill"
            case "bolt": return "bolt.fill"
            case "heart": return "heart.fill"
            case "terminal_home": return "house.fill"
            default: return "sparkles"
            }
        }
        if iconString.hasPrefix("emoji:") {
            return "sparkles"
        }
        return iconString
    }
}

// MARK: - Crisp 11×11 Pixel-Matrix Glyph Renderer for Omarchy Themes

public struct OmarchyPixelGlyphView: View {
    public let glyphKey: String
    public let color: Color
    public var pixelSize: CGFloat

    public init(glyphKey: String, color: Color, pixelSize: CGFloat = 2.0) {
        self.glyphKey = glyphKey
        self.color = color
        self.pixelSize = pixelSize
    }

    public var body: some View {
        let rows = Self.bitmap(for: glyphKey)
        Canvas { context, size in
            let gridCount = 11
            let cell = min(size.width, size.height) / CGFloat(gridCount)
            let xOrigin = (size.width - cell * CGFloat(gridCount)) * 0.5
            let yOrigin = (size.height - cell * CGFloat(gridCount)) * 0.5

            for (rIdx, row) in rows.enumerated() where rIdx < gridCount {
                for (cIdx, ch) in row.enumerated() where cIdx < gridCount {
                    if ch == "#" {
                        let rect = CGRect(
                            x: xOrigin + CGFloat(cIdx) * cell,
                            y: yOrigin + CGFloat(rIdx) * cell,
                            width: ceil(cell),
                            height: ceil(cell)
                        )
                        context.fill(Path(rect), with: .color(color))
                    } else if ch == "." {
                        let rect = CGRect(
                            x: xOrigin + CGFloat(cIdx) * cell,
                            y: yOrigin + CGFloat(rIdx) * cell,
                            width: ceil(cell),
                            height: ceil(cell)
                        )
                        context.fill(Path(rect), with: .color(color.opacity(0.42)))
                    }
                }
            }
        }
        .frame(width: pixelSize * 11, height: pixelSize * 11)
        .accessibilityHidden(true)
    }

    // 11x11 crisp pixel matrices ('#' = solid foreground, '.' = accent halftone, ' ' = transparent)
    private static func bitmap(for key: String) -> [String] {
        switch key {
        case "dishes":
            return [
                "        #  ",
                "       ### ",
                "  ##### #  ",
                " #.....#   ",
                "#..###..#  ",
                "#.#   #.#  ",
                "#..###..#  ",
                " #.....#   ",
                "  #####    ",
                "#########  ",
                " #######   "
            ]
        case "mug":
            return [
                "  .  .     ",
                "   .  .    ",
                "           ",
                " ########  ",
                " #......###",
                " #......# #",
                " #......# #",
                " #......###",
                " #......#  ",
                "  ######   ",
                " ########  "
            ]
        case "fridge":
            return [
                "  #######  ",
                "  #.....#  ",
                "  #.#...#  ",
                "  #.....#  ",
                "  #######  ",
                "  #.....#  ",
                "  #.#...#  ",
                "  #.#...#  ",
                "  #.....#  ",
                "  #######  ",
                "  #     #  "
            ]
        case "trash":
            return [
                "   #####   ",
                " ######### ",
                "           ",
                "  #######  ",
                "  #.#.#.#  ",
                "  #.#.#.#  ",
                "  #.#.#.#  ",
                "  #.#.#.#  ",
                "  #.#.#.#  ",
                "  #######  ",
                "           "
            ]
        case "droplet":
            return [
                "     #     ",
                "    ###    ",
                "    ###    ",
                "   #####   ",
                "  ##...##  ",
                " ##.....## ",
                " ##.#...## ",
                " ##..#..## ",
                "  #######  ",
                "   #####   ",
                "           "
            ]
        case "shower":
            return [
                "  ######   ",
                "  #    #   ",
                "       ##  ",
                "     ##### ",
                "    #######",
                "           ",
                "    . . .  ",
                "   . . .   ",
                "    . . .  ",
                "   . . .   ",
                "           "
            ]
        case "bed":
            return [
                "       ..  ",
                " #    .    ",
                " #     ..  ",
                " #         ",
                " # ###     ",
                " ######### ",
                " #.......# ",
                " ######### ",
                " #       # ",
                " #       # ",
                "           "
            ]
        case "sofa":
            return [
                "           ",
                "           ",
                "  #######  ",
                "  #.....#  ",
                "###.....###",
                "#.#.....#.#",
                "###########",
                "#.........#",
                "###########",
                " #       # ",
                "           "
            ]
        case "washer":
            return [
                " ######### ",
                " #..   #.# ",
                " ######### ",
                " #  ###  # ",
                " # #...# # ",
                " # #...# # ",
                " # #...# # ",
                " #  ###  # ",
                " #       # ",
                " ######### ",
                "           "
            ]
        case "hanger":
            return [
                "    ###    ",
                "   #   #   ",
                "      #    ",
                "     #     ",
                "    ###    ",
                "  ##   ##  ",
                " ##     ## ",
                "###########",
                "           ",
                "  .......  ",
                "           "
            ]
        case "broom":
            return [
                "        ## ",
                "       ##  ",
                "      ##   ",
                "     ##    ",
                "    ##     ",
                "   ####    ",
                "  ######   ",
                " ###..###  ",
                "###.##.### ",
                " ##.##.##  ",
                "           "
            ]
        case "plant":
            return [
                "   ##      ",
                "  #### ##  ",
                "   ## #### ",
                "    # ##   ",
                "     #     ",
                "     #     ",
                "  #######  ",
                "   #...#   ",
                "   #...#   ",
                "    ###    ",
                "           "
            ]
        case "cat":
            return [
                " ##     ## ",
                " ###   ### ",
                " ######### ",
                " ##.###.## ",
                " ######### ",
                " #..###..# ",
                "  #######  ",
                "    ###    ",
                "   #####   ",
                "   ## ##   ",
                "           "
            ]
        case "dog":
            return [
                "###     ###",
                "#.##   ##.#",
                "# ####### #",
                "  ##.#.##  ",
                "  #######  ",
                "  ###.###  ",
                "   #####   ",
                "    ###    ",
                "   #####   ",
                "   #   #   ",
                "           "
            ]
        case "paw":
            return [
                "  ##   ##  ",
                "  ##   ##  ",
                "##       ##",
                "##       ##",
                "   #####   ",
                "  #######  ",
                " ######### ",
                " ###...### ",
                "  ##...##  ",
                "           ",
                "           "
            ]
        case "desk":
            return [
                " ######### ",
                " #.......# ",
                " #..>_...# ",
                " #.......# ",
                " ######### ",
                "    ###    ",
                "   #####   ",
                "           ",
                "###########",
                " #       # ",
                "           "
            ]
        case "terminal":
            return [
                "###########",
                "#.........#",
                "#. #      #",
                "#.  #     #",
                "#.   #    #",
                "#.  #     #",
                "#. #  ### #",
                "#.........#",
                "###########",
                "           ",
                "           "
            ]
        case "ghost":
            return [
                "   #####   ",
                "  #######  ",
                " ######### ",
                " ## ### ## ",
                " ######### ",
                " ######### ",
                " ######### ",
                " ######### ",
                " ## ### ## ",
                " #   #   # ",
                "           "
            ]
        case "arch":
            return [
                "     #     ",
                "     #     ",
                "    ###    ",
                "    ###    ",
                "   ##.##   ",
                "   #####   ",
                "  ### ###  ",
                "  ##   ##  ",
                " ##     ## ",
                "##       ##",
                "           "
            ]
        case "wave":
            return [
                "   ####    ",
                "  ##  ##   ",
                " ##    #   ",
                "###        ",
                "#####  ### ",
                "######..#  ",
                "#########  ",
                "........... ",
                "###########",
                "           ",
                "           "
            ]
        case "pill":
            return [
                "      ###  ",
                "     ##### ",
                "    ##...##",
                "   ##....##",
                "  ####..## ",
                " #####.##  ",
                "#######    ",
                "#######    ",
                " #####     ",
                "  ###      ",
                "           "
            ]
        case "cart":
            return [
                "##         ",
                " ## ###### ",
                "  ######## ",
                "  #.#.#.#  ",
                "  #######  ",
                "   #####   ",
                "   #       ",
                "   ######  ",
                "   ##  ##  ",
                "   ##  ##  ",
                "           "
            ]
        case "mail":
            return [
                "           ",
                "###########",
                "##.......##",
                "#.#.....#.#",
                "#..#...#..#",
                "#...###...#",
                "#.........#",
                "#.........#",
                "###########",
                "           ",
                "           "
            ]
        case "bolt":
            return [
                "      ###  ",
                "     ###   ",
                "    ###    ",
                "   ###     ",
                "  ######## ",
                "     ####  ",
                "    ###    ",
                "   ###     ",
                "  ###      ",
                "  #        ",
                "           "
            ]
        case "heart":
            return [
                "           ",
                " ###   ### ",
                "##### #####",
                "###########",
                "###########",
                " ######### ",
                "  #######  ",
                "   #####   ",
                "    ###    ",
                "     #     ",
                "           "
            ]
        case "terminal_home":
            return [
                "     #     ",
                "   #####   ",
                "  #######  ",
                " ######### ",
                "  #.....#  ",
                "  #.> ..#  ",
                "  #.._..#  ",
                "  #.....#  ",
                "  #######  ",
                "           ",
                "           "
            ]
        default: // "spark"
            return [
                "     #     ",
                "     #   . ",
                "    ### ... ",
                "    ###  . ",
                "###########",
                "   #####   ",
                "    ###    ",
                " .  ###    ",
                "...  #     ",
                " .   #     ",
                "           "
            ]
        }
    }
}

// MARK: - Unified Theme-Aware Chore & Room Icon View

public struct ChoreIconBadgeView: View {
    @Environment(\.adhousedTheme) private var theme
    public let iconSymbol: String
    public let tint: Color
    public var size: CGFloat
    public var styleOverride: IconStylePreference?

    public init(
        iconSymbol: String,
        tint: Color,
        size: CGFloat = 44,
        styleOverride: IconStylePreference? = nil
    ) {
        self.iconSymbol = iconSymbol
        self.tint = tint
        self.size = size
        self.styleOverride = styleOverride
    }

    private var effectiveStyle: IconStylePreference {
        let pref = styleOverride ?? ADHOUSEDPreferences.shared.iconStylePreference
        if pref != .autoTheme {
            return pref
        }
        if theme.isTerminalHUD {
            return .omarchyPixelHUD
        }
        if theme.preset.isQuietMinimalFamily {
            return .minimalOutline
        }
        if theme.usesHardOffsetShadow {
            return .boldBadge
        }
        return .softMedallion
    }

    public var body: some View {
        let style = effectiveStyle
        let radius: CGFloat = {
            switch style {
            case .omarchyPixelHUD: return max(5, size * 0.16)
            case .minimalOutline: return size * 0.26
            case .softMedallion: return size * 0.30
            case .boldBadge: return size * 0.24
            case .autoTheme: return size * 0.26
            }
        }()

        ZStack {
            // Background Container
            switch style {
            case .omarchyPixelHUD:
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(theme.canvasSecondary.opacity(theme.isDark ? 0.92 : 0.78))
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(tint.opacity(0.50), lineWidth: 1.1)
                    }
                    .overlay {
                        // Subtle Hyprland / Waybar HUD corner brackets
                        HUDCornerBracketsShape(bracketLength: max(3.5, size * 0.13))
                            .stroke(tint.opacity(0.85), lineWidth: 1.2)
                            .padding(2.5)
                    }

            case .minimalOutline:
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(tint.opacity(theme.isDark ? 0.10 : 0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(tint.opacity(0.26), lineWidth: 1.0)
                    }

            case .boldBadge:
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(tint)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(theme.borderInk, lineWidth: theme.usesHardOffsetShadow ? 1.6 : 1.0)
                    }

            case .softMedallion, .autoTheme:
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(tint.opacity(theme.isDark ? 0.20 : 0.14))
            }

            // Foreground Glyph
            glyphContent(for: style)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func glyphContent(for style: IconStylePreference) -> some View {
        let fgColor: Color = (style == .boldBadge) ? .white : tint
        if iconSymbol.hasPrefix("emoji:") {
            let emoji = String(iconSymbol.dropFirst("emoji:".count))
            Text(emoji)
                .font(.system(size: size * 0.50))
        } else if iconSymbol.hasPrefix("omarchy:") {
            let key = String(iconSymbol.dropFirst("omarchy:".count))
            OmarchyPixelGlyphView(
                glyphKey: key,
                color: fgColor,
                pixelSize: max(1.4, (size * 0.54) / 11.0)
            )
        } else if style == .omarchyPixelHUD,
                  let mappedKey = ChoreIconCatalog.mappedOmarchyGlyphKey(for: iconSymbol) {
            OmarchyPixelGlyphView(
                glyphKey: mappedKey,
                color: fgColor,
                pixelSize: max(1.4, (size * 0.54) / 11.0)
            )
        } else {
            Image(systemName: iconSymbol)
                .font(.system(
                    size: size * 0.43,
                    weight: style == .minimalOutline ? .medium : .bold
                ))
                .foregroundStyle(fgColor)
        }
    }
}

private struct HUDCornerBracketsShape: Shape {
    let bracketLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let l = min(bracketLength, min(rect.width, rect.height) * 0.35)
        // Top-left
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))
        // Top-right
        p.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))
        // Bottom-left
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY - l))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + l, y: rect.maxY))
        // Bottom-right
        p.move(to: CGPoint(x: rect.maxX - l, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - l))
        return p
    }
}
