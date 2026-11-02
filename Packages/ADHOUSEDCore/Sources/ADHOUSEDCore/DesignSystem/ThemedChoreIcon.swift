import SwiftUI

// MARK: - Modern Stylized Vector & Duotone Chore Icon System

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
    case omarchyPixel      // Raw identifier preserved; now "Omarchy Cyber Vector"
    case homeAndRooms
    case petsPlantsOutdoor
    case techLifeSelfCare
    case expressiveEmoji

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .omarchyPixel: return "Omarchy Vector"
        case .homeAndRooms: return "Home & Cleaning"
        case .petsPlantsOutdoor: return "Pets & Botanicals"
        case .techLifeSelfCare: return "Desk & Self-Care"
        case .expressiveEmoji: return "Expressive Emoji"
        }
    }
}

public enum ChoreIconCatalog {
    public static let allChoices: [ChoreIconChoice] = [
        // 1. Bespoke Modern Stylized Omarchy & Geometric Vector Glyphs
        .init(id: "omarchy:prism", label: "Omarchy Prism", pack: .omarchyPixel),
        .init(id: "omarchy:arch", label: "Faceted Peak", pack: .omarchyPixel),
        .init(id: "omarchy:terminal", label: "Terminal >_", pack: .omarchyPixel),
        .init(id: "omarchy:ghost", label: "Ghostty", pack: .omarchyPixel),
        .init(id: "omarchy:spark", label: "Star Spark", pack: .omarchyPixel),
        .init(id: "omarchy:dishes", label: "Clean Dishes", pack: .omarchyPixel),
        .init(id: "omarchy:mug", label: "Coffee / Tea", pack: .omarchyPixel),
        .init(id: "omarchy:fridge", label: "Fridge Reset", pack: .omarchyPixel),
        .init(id: "omarchy:trash", label: "Curb Bin", pack: .omarchyPixel),
        .init(id: "omarchy:droplet", label: "Hydro Drop", pack: .omarchyPixel),
        .init(id: "omarchy:shower", label: "Rain Shower", pack: .omarchyPixel),
        .init(id: "omarchy:bed", label: "Platform Bed", pack: .omarchyPixel),
        .init(id: "omarchy:sofa", label: "Lounge Sofa", pack: .omarchyPixel),
        .init(id: "omarchy:washer", label: "Drum Washer", pack: .omarchyPixel),
        .init(id: "omarchy:hanger", label: "Wardrobe", pack: .omarchyPixel),
        .init(id: "omarchy:broom", label: "Sweep", pack: .omarchyPixel),
        .init(id: "omarchy:plant", label: "Botanical", pack: .omarchyPixel),
        .init(id: "omarchy:cat", label: "Origami Cat", pack: .omarchyPixel),
        .init(id: "omarchy:dog", label: "Modern Hound", pack: .omarchyPixel),
        .init(id: "omarchy:paw", label: "Pet Care", pack: .omarchyPixel),
        .init(id: "omarchy:desk", label: "Workstation", pack: .omarchyPixel),
        .init(id: "omarchy:wave", label: "Kanagawa", pack: .omarchyPixel),
        .init(id: "omarchy:pill", label: "Meds Capsule", pack: .omarchyPixel),
        .init(id: "omarchy:cart", label: "Market Tote", pack: .omarchyPixel),
        .init(id: "omarchy:mail", label: "Inbox / Bills", pack: .omarchyPixel),
        .init(id: "omarchy:bolt", label: "Quick Voltage", pack: .omarchyPixel),
        .init(id: "omarchy:heart", label: "Vitality", pack: .omarchyPixel),
        .init(id: "omarchy:terminal_home", label: "Home Node", pack: .omarchyPixel),

        // 2. Home & Cleaning Duotone SF Symbols
        .init(id: "sparkles", label: "Sparkles", pack: .homeAndRooms),
        .init(id: "dishwasher.fill", label: "Dishwasher", pack: .homeAndRooms),
        .init(id: "sink.fill", label: "Sink", pack: .homeAndRooms),
        .init(id: "refrigerator.fill", label: "Fridge", pack: .homeAndRooms),
        .init(id: "fork.knife", label: "Kitchen", pack: .homeAndRooms),
        .init(id: "cup.and.saucer.fill", label: "Coffee / Tea", pack: .homeAndRooms),
        .init(id: "mug.fill", label: "Mug", pack: .homeAndRooms),
        .init(id: "frying.pan.fill", label: "Cookware", pack: .homeAndRooms),
        .init(id: "waterbottle.fill", label: "Hydration", pack: .homeAndRooms),
        .init(id: "shower.fill", label: "Shower", pack: .homeAndRooms),
        .init(id: "bathtub.fill", label: "Bathtub", pack: .homeAndRooms),
        .init(id: "toilet.fill", label: "Bath Reset", pack: .homeAndRooms),
        .init(id: "bed.double.fill", label: "Bedsheets", pack: .homeAndRooms),
        .init(id: "sofa.fill", label: "Living Room", pack: .homeAndRooms),
        .init(id: "lamp.floor.fill", label: "Lighting", pack: .homeAndRooms),
        .init(id: "washer.fill", label: "Washer", pack: .homeAndRooms),
        .init(id: "dryer.fill", label: "Dryer", pack: .homeAndRooms),
        .init(id: "tshirt.fill", label: "Laundry", pack: .homeAndRooms),
        .init(id: "hanger", label: "Closet", pack: .homeAndRooms),
        .init(id: "cabinet.fill", label: "Organizer", pack: .homeAndRooms),
        .init(id: "fanblades.fill", label: "Air / Vacuum", pack: .homeAndRooms),
        .init(id: "drop.triangle.fill", label: "Mop Floors", pack: .homeAndRooms),
        .init(id: "trash.fill", label: "Trash", pack: .homeAndRooms),
        .init(id: "arrow.up.bin.fill", label: "Curb Bins", pack: .homeAndRooms),

        // 3. Pets, Botanicals & Outdoors
        .init(id: "leaf.fill", label: "Plants", pack: .petsPlantsOutdoor),
        .init(id: "camera.macro", label: "Blooms", pack: .petsPlantsOutdoor),
        .init(id: "tree.fill", label: "Garden", pack: .petsPlantsOutdoor),
        .init(id: "pawprint.fill", label: "Pet Care", pack: .petsPlantsOutdoor),
        .init(id: "cat.fill", label: "Cat", pack: .petsPlantsOutdoor),
        .init(id: "dog.fill", label: "Dog", pack: .petsPlantsOutdoor),
        .init(id: "tray.full.fill", label: "Litter Box", pack: .petsPlantsOutdoor),
        .init(id: "fish.fill", label: "Aquarium", pack: .petsPlantsOutdoor),
        .init(id: "bird.fill", label: "Bird", pack: .petsPlantsOutdoor),
        .init(id: "car.fill", label: "Car", pack: .petsPlantsOutdoor),
        .init(id: "bicycle", label: "Cycle", pack: .petsPlantsOutdoor),
        .init(id: "sun.max.fill", label: "Daylight", pack: .petsPlantsOutdoor),

        // 4. Desk, Self-Care & Life Admin
        .init(id: "desktopcomputer", label: "Workstation", pack: .techLifeSelfCare),
        .init(id: "laptopcomputer", label: "Laptop", pack: .techLifeSelfCare),
        .init(id: "keyboard.fill", label: "Keyboard", pack: .techLifeSelfCare),
        .init(id: "gamecontroller.fill", label: "Console", pack: .techLifeSelfCare),
        .init(id: "pills.fill", label: "Vitamins / Meds", pack: .techLifeSelfCare),
        .init(id: "heart.fill", label: "Self-Care", pack: .techLifeSelfCare),
        .init(id: "dumbbell.fill", label: "Movement", pack: .techLifeSelfCare),
        .init(id: "cart.fill", label: "Groceries", pack: .techLifeSelfCare),
        .init(id: "creditcard.fill", label: "Bills / Admin", pack: .techLifeSelfCare),
        .init(id: "envelope.open.fill", label: "Mail", pack: .techLifeSelfCare),
        .init(id: "backpack.fill", label: "Bag Reset", pack: .techLifeSelfCare),
        .init(id: "book.fill", label: "Reading", pack: .techLifeSelfCare),

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

    /// Maps standard SF Symbols automatically to modern stylized Omarchy vector glyphs when Omarchy vector mode is active.
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
        case "sparkles", "sparkles.rectangle.stack.fill", "aqi.medium", "plus.square.on.square":
            return "spark"
        case "icloud.and.arrow.up.fill":
            return "prism"
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
            case "terminal", "ghost", "arch", "prism": return "terminal.fill"
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

// MARK: - Sleek Modern Stylized Vector & Duotone Glyph Renderer (24×24 Bezier Space)

public struct StylizedVectorGlyphView: View {
    public let glyphKey: String
    public let primaryColor: Color
    public var secondaryColor: Color?
    public var glyphSize: CGFloat

    public init(
        glyphKey: String,
        primaryColor: Color,
        secondaryColor: Color? = nil,
        glyphSize: CGFloat = 22
    ) {
        self.glyphKey = glyphKey
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.glyphSize = glyphSize
    }

    public var body: some View {
        let sec = secondaryColor ?? primaryColor.opacity(0.75)

        Canvas { context, size in
            let s = min(size.width, size.height) / 24.0
            let ox = (size.width - 24.0 * s) * 0.5
            let oy = (size.height - 24.0 * s) * 0.5

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: ox + x * s, y: oy + y * s)
            }
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s)
            }
            func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
                Path(roundedRect: rect(x, y, w, h), cornerRadius: r * s, style: .continuous)
            }

            let strokeStyle = StrokeStyle(
                lineWidth: max(1.35, 1.85 * s),
                lineCap: .round,
                lineJoin: .round
            )
            let fineStroke = StrokeStyle(
                lineWidth: max(1.05, 1.35 * s),
                lineCap: .round,
                lineJoin: .round
            )

            let lineShading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [primaryColor, sec]),
                startPoint: pt(2, 2),
                endPoint: pt(22, 22)
            )
            let chamberShading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [primaryColor.opacity(0.30), sec.opacity(0.12)]),
                startPoint: pt(4, 3),
                endPoint: pt(20, 21)
            )
            let solidAccent = GraphicsContext.Shading.color(primaryColor)

            switch glyphKey {
            case "prism":
                // Omarchy signature Circle · Split Chevron · Diamond
                let cPath = Path(ellipseIn: rect(1.6, 7.2, 6.8, 9.6))
                context.fill(cPath, with: chamberShading)
                context.stroke(cPath, with: lineShading, style: fineStroke)

                var chev = Path()
                chev.move(to: pt(9.8, 7.2))
                chev.addLine(to: pt(12.6, 7.2))
                chev.addLine(to: pt(15.2, 12.0))
                chev.addLine(to: pt(12.6, 16.8))
                chev.addLine(to: pt(9.8, 16.8))
                chev.addLine(to: pt(12.2, 12.0))
                chev.closeSubpath()
                context.fill(chev, with: lineShading)

                var dia = Path()
                dia.move(to: pt(19.0, 7.0))
                dia.addLine(to: pt(22.6, 12.0))
                dia.addLine(to: pt(19.0, 17.0))
                dia.addLine(to: pt(15.6, 12.0))
                dia.closeSubpath()
                context.fill(dia, with: chamberShading)
                context.stroke(dia, with: lineShading, style: fineStroke)

            case "arch":
                // Sleek modern faceted geometric peak
                var outer = Path()
                outer.move(to: pt(12, 2.5))
                outer.addLine(to: pt(21, 20))
                outer.addLine(to: pt(15.4, 20))
                outer.addLine(to: pt(12, 13.2))
                outer.addLine(to: pt(8.6, 20))
                outer.addLine(to: pt(3, 20))
                outer.closeSubpath()
                context.fill(outer, with: chamberShading)
                context.stroke(outer, with: lineShading, style: strokeStyle)

                var facet = Path()
                facet.move(to: pt(12, 2.5))
                facet.addLine(to: pt(12, 13.2))
                context.stroke(facet, with: solidAccent, style: fineStroke)

            case "terminal":
                // Modern Hyprland / Ghostty terminal window with >_ prompt
                let win = rrect(2.5, 4.0, 19.0, 16.0, 3.6)
                context.fill(win, with: chamberShading)
                context.stroke(win, with: lineShading, style: strokeStyle)

                var topBar = Path()
                topBar.move(to: pt(3.2, 8.2))
                topBar.addLine(to: pt(20.8, 8.2))
                context.stroke(topBar, with: lineShading, style: fineStroke)

                var prompt = Path()
                prompt.move(to: pt(7.0, 11.4))
                prompt.addLine(to: pt(10.2, 14.0))
                prompt.addLine(to: pt(7.0, 16.6))
                prompt.move(to: pt(12.2, 16.6))
                prompt.addLine(to: pt(16.6, 16.6))
                context.stroke(prompt, with: solidAccent, style: strokeStyle)

            case "ghost":
                // Smooth stylized Ghostty spirit with visor eyes
                var g = Path()
                g.move(to: pt(5.5, 19.5))
                g.addLine(to: pt(5.5, 10.5))
                g.addCurve(to: pt(18.5, 10.5), control1: pt(5.5, 2.8), control2: pt(18.5, 2.8))
                g.addLine(to: pt(18.5, 19.5))
                g.addLine(to: pt(15.3, 17.3))
                g.addLine(to: pt(12.0, 19.6))
                g.addLine(to: pt(8.7, 17.3))
                g.closeSubpath()
                context.fill(g, with: chamberShading)
                context.stroke(g, with: lineShading, style: strokeStyle)

                context.fill(rrect(8.6, 9.6, 2.2, 3.2, 1.1), with: solidAccent)
                context.fill(rrect(13.2, 9.6, 2.2, 3.2, 1.1), with: solidAccent)

            case "dishes":
                // Overlapping sleek ceramic plate + sparkling star
                let outerPlate = Path(ellipseIn: rect(2.5, 4.5, 15.5, 15.5))
                let innerRim = Path(ellipseIn: rect(5.6, 7.6, 9.3, 9.3))
                context.fill(outerPlate, with: chamberShading)
                context.stroke(outerPlate, with: lineShading, style: strokeStyle)
                context.stroke(innerRim, with: lineShading, style: fineStroke)

                // Crisp 4-point sparkle top-right
                var sp = Path()
                sp.move(to: pt(19.2, 2.6))
                sp.addQuadCurve(to: pt(22.0, 5.4), control: pt(19.5, 5.1))
                sp.addQuadCurve(to: pt(19.2, 8.2), control: pt(19.5, 5.7))
                sp.addQuadCurve(to: pt(16.4, 5.4), control: pt(18.9, 5.7))
                sp.addQuadCurve(to: pt(19.2, 2.6), control: pt(18.9, 5.1))
                sp.closeSubpath()
                context.fill(sp, with: solidAccent)

            case "mug":
                // Modern espresso cup + handle + rising S-wave steam
                let cup = rrect(4.0, 9.0, 12.0, 10.5, 3.2)
                context.fill(cup, with: chamberShading)
                context.stroke(cup, with: lineShading, style: strokeStyle)

                var handle = Path()
                handle.move(to: pt(16.0, 11.0))
                handle.addCurve(to: pt(16.0, 17.0), control1: pt(20.6, 11.0), control2: pt(20.6, 17.0))
                context.stroke(handle, with: lineShading, style: strokeStyle)

                var steam = Path()
                steam.move(to: pt(8.0, 6.8))
                steam.addCurve(to: pt(8.4, 3.0), control1: pt(6.8, 5.2), control2: pt(9.5, 4.5))
                steam.move(to: pt(12.2, 6.8))
                steam.addCurve(to: pt(12.6, 3.0), control1: pt(11.0, 5.2), control2: pt(13.7, 4.5))
                context.stroke(steam, with: solidAccent, style: fineStroke)

            case "fridge":
                // Sleek modern monolith refrigerator with split doors & vertical handles
                let bodyPath = rrect(5.0, 2.5, 14.0, 19.0, 3.0)
                context.fill(bodyPath, with: chamberShading)
                context.stroke(bodyPath, with: lineShading, style: strokeStyle)

                var split = Path()
                split.move(to: pt(5.5, 10.2))
                split.addLine(to: pt(18.5, 10.2))
                split.move(to: pt(8.2, 5.4))
                split.addLine(to: pt(8.2, 8.0))
                split.move(to: pt(8.2, 12.6))
                split.addLine(to: pt(8.2, 17.2))
                context.stroke(split, with: solidAccent, style: strokeStyle)

            case "trash":
                // Tapered architectural bin with floating lid & vertical flutes
                var bin = Path()
                bin.move(to: pt(6.2, 7.6))
                bin.addLine(to: pt(17.8, 7.6))
                bin.addLine(to: pt(16.6, 20.5))
                bin.addQuadCurve(to: pt(14.8, 21.5), control: pt(16.5, 21.5))
                bin.addLine(to: pt(9.2, 21.5))
                bin.addQuadCurve(to: pt(7.4, 20.5), control: pt(7.5, 21.5))
                bin.closeSubpath()
                context.fill(bin, with: chamberShading)
                context.stroke(bin, with: lineShading, style: strokeStyle)

                var lid = Path()
                lid.move(to: pt(4.2, 5.2))
                lid.addLine(to: pt(19.8, 5.2))
                lid.move(to: pt(9.5, 5.0))
                lid.addLine(to: pt(10.2, 3.0))
                lid.addLine(to: pt(13.8, 3.0))
                lid.addLine(to: pt(14.5, 5.0))
                lid.move(to: pt(10.2, 10.8))
                lid.addLine(to: pt(10.6, 18.0))
                lid.move(to: pt(13.8, 10.8))
                lid.addLine(to: pt(13.4, 18.0))
                context.stroke(lid, with: lineShading, style: fineStroke)

            case "droplet":
                // Smooth hydro-teardrop with inner specular arc
                var drop = Path()
                drop.move(to: pt(12, 2.8))
                drop.addCurve(to: pt(18.8, 14.6), control1: pt(15.8, 7.8), control2: pt(18.8, 11.2))
                drop.addCurve(to: pt(5.2, 14.6), control1: pt(18.8, 19.2), control2: pt(5.2, 19.2))
                drop.addCurve(to: pt(12, 2.8), control1: pt(5.2, 11.2), control2: pt(8.2, 7.8))
                drop.closeSubpath()
                context.fill(drop, with: chamberShading)
                context.stroke(drop, with: lineShading, style: strokeStyle)

                var gleam = Path()
                gleam.move(to: pt(8.8, 13.6))
                gleam.addQuadCurve(to: pt(11.4, 17.2), control: pt(8.6, 16.6))
                context.stroke(gleam, with: solidAccent, style: fineStroke)

            case "shower":
                // Overhead rain shower disc + diagonal hydro streams
                var head = Path()
                head.move(to: pt(12, 3.0))
                head.addLine(to: pt(12, 6.2))
                head.move(to: pt(6.5, 9.5))
                head.addCurve(to: pt(17.5, 9.5), control1: pt(6.5, 5.2), control2: pt(17.5, 5.2))
                head.closeSubpath()
                context.fill(head, with: chamberShading)
                context.stroke(head, with: lineShading, style: strokeStyle)

                var rain = Path()
                for x in [8.0, 12.0, 16.0] {
                    rain.move(to: pt(x, 12.4))
                    rain.addLine(to: pt(x - 0.8, 14.8))
                    rain.move(to: pt(x - 0.4, 17.4))
                    rain.addLine(to: pt(x - 1.2, 19.8))
                }
                context.stroke(rain, with: solidAccent, style: fineStroke)

            case "bed":
                // Architectural low-profile bed with plush pillows
                let mattress = rrect(3.0, 12.0, 18.0, 5.2, 2.0)
                context.fill(mattress, with: chamberShading)
                context.stroke(mattress, with: lineShading, style: strokeStyle)

                var frame = Path()
                frame.move(to: pt(3.5, 6.2))
                frame.addLine(to: pt(3.5, 20.2))
                frame.move(to: pt(20.5, 14.5))
                frame.addLine(to: pt(20.5, 20.2))
                context.stroke(frame, with: lineShading, style: strokeStyle)

                let pillow1 = rrect(5.6, 8.6, 5.4, 3.4, 1.4)
                let pillow2 = rrect(12.2, 8.6, 5.4, 3.4, 1.4)
                context.stroke(pillow1, with: solidAccent, style: fineStroke)
                context.stroke(pillow2, with: solidAccent, style: fineStroke)

            case "sofa":
                // Modern modular lounge sofa
                let back = rrect(4.5, 6.0, 15.0, 7.5, 2.8)
                context.fill(back, with: chamberShading)
                context.stroke(back, with: lineShading, style: strokeStyle)

                let seat = rrect(2.5, 11.2, 19.0, 6.2, 2.4)
                context.fill(seat, with: chamberShading)
                context.stroke(seat, with: lineShading, style: strokeStyle)

                var legs = Path()
                legs.move(to: pt(5.5, 17.5))
                legs.addLine(to: pt(4.8, 20.2))
                legs.move(to: pt(18.5, 17.5))
                legs.addLine(to: pt(19.2, 20.2))
                context.stroke(legs, with: lineShading, style: strokeStyle)

            case "washer":
                // Front-load drum washer with S-wave water line
                let chassis = rrect(4.0, 2.8, 16.0, 18.4, 3.4)
                context.fill(chassis, with: chamberShading)
                context.stroke(chassis, with: lineShading, style: strokeStyle)

                let drum = Path(ellipseIn: rect(7.2, 8.2, 9.6, 9.6))
                context.stroke(drum, with: lineShading, style: strokeStyle)

                var wave = Path()
                wave.move(to: pt(7.8, 13.2))
                wave.addCurve(to: pt(16.2, 13.2), control1: pt(10.2, 10.8), control2: pt(13.8, 15.6))
                context.stroke(wave, with: solidAccent, style: fineStroke)

                context.fill(Path(ellipseIn: rect(15.6, 5.0, 2.0, 2.0)), with: solidAccent)

            case "hanger":
                // Minimalist anodized geometric hanger
                var hook = Path()
                hook.move(to: pt(10.2, 6.0))
                hook.addCurve(to: pt(13.8, 6.0), control1: pt(10.2, 2.8), control2: pt(14.5, 3.0))
                hook.addQuadCurve(to: pt(12.0, 9.0), control: pt(13.8, 7.8))
                context.stroke(hook, with: lineShading, style: strokeStyle)

                var tri = Path()
                tri.move(to: pt(12.0, 9.0))
                tri.addLine(to: pt(20.8, 16.8))
                tri.addQuadCurve(to: pt(19.8, 18.6), control: pt(21.4, 18.4))
                tri.addLine(to: pt(4.2, 18.6))
                tri.addQuadCurve(to: pt(3.2, 16.8), control: pt(2.6, 18.4))
                tri.closeSubpath()
                context.fill(tri, with: chamberShading)
                context.stroke(tri, with: lineShading, style: strokeStyle)

            case "broom":
                // Sleek angled modern vacuum / sweep nozzle + sparkle
                var wand = Path()
                wand.move(to: pt(18.5, 3.2))
                wand.addLine(to: pt(10.5, 13.5))
                context.stroke(wand, with: lineShading, style: strokeStyle)

                var head = Path()
                head.move(to: pt(5.8, 13.5))
                head.addLine(to: pt(15.2, 13.5))
                head.addLine(to: pt(17.2, 19.5))
                head.addLine(to: pt(3.8, 19.5))
                head.closeSubpath()
                context.fill(head, with: chamberShading)
                context.stroke(head, with: lineShading, style: strokeStyle)

                context.fill(Path(ellipseIn: rect(6.2, 5.5, 2.4, 2.4)), with: solidAccent)

            case "plant":
                // Stylized botanical twin-leaf + tapered planter
                var leftLeaf = Path()
                leftLeaf.move(to: pt(12, 13.5))
                leftLeaf.addCurve(to: pt(5.2, 6.2), control1: pt(6.5, 13.0), control2: pt(4.8, 9.2))
                leftLeaf.addCurve(to: pt(12, 13.5), control1: pt(9.5, 5.8), control2: pt(12.0, 9.0))
                context.fill(leftLeaf, with: chamberShading)
                context.stroke(leftLeaf, with: lineShading, style: fineStroke)

                var rightLeaf = Path()
                rightLeaf.move(to: pt(12, 12.2))
                rightLeaf.addCurve(to: pt(18.8, 4.8), control1: pt(17.5, 11.8), control2: pt(19.2, 7.8))
                rightLeaf.addCurve(to: pt(12, 12.2), control1: pt(14.5, 4.4), control2: pt(12.0, 7.6))
                context.fill(rightLeaf, with: chamberShading)
                context.stroke(rightLeaf, with: lineShading, style: fineStroke)

                var pot = Path()
                pot.move(to: pt(7.2, 14.2))
                pot.addLine(to: pt(16.8, 14.2))
                pot.addLine(to: pt(15.2, 20.8))
                pot.addLine(to: pt(8.8, 20.8))
                pot.closeSubpath()
                context.fill(pot, with: chamberShading)
                context.stroke(pot, with: lineShading, style: strokeStyle)

            case "cat":
                // Sleek geometric origami cat silhouette
                var cat = Path()
                cat.move(to: pt(4.8, 11.2))
                cat.addLine(to: pt(5.4, 4.2))
                cat.addLine(to: pt(9.8, 7.8))
                cat.addLine(to: pt(14.2, 7.8))
                cat.addLine(to: pt(18.6, 4.2))
                cat.addLine(to: pt(19.2, 11.2))
                cat.addCurve(to: pt(12.0, 20.0), control1: pt(19.5, 16.8), control2: pt(16.0, 20.0))
                cat.addCurve(to: pt(4.8, 11.2), control1: pt(8.0, 20.0), control2: pt(4.5, 16.8))
                cat.closeSubpath()
                context.fill(cat, with: chamberShading)
                context.stroke(cat, with: lineShading, style: strokeStyle)

                context.fill(Path(ellipseIn: rect(8.2, 11.5, 2.2, 2.2)), with: solidAccent)
                context.fill(Path(ellipseIn: rect(13.6, 11.5, 2.2, 2.2)), with: solidAccent)

            case "dog":
                // Sleek modern geometric hound face with folded ears
                var head = Path()
                head.move(to: pt(6.5, 7.5))
                head.addLine(to: pt(17.5, 7.5))
                head.addLine(to: pt(18.5, 15.2))
                head.addQuadCurve(to: pt(12.0, 20.2), control: pt(16.8, 20.2))
                head.addQuadCurve(to: pt(5.5, 15.2), control: pt(7.2, 20.2))
                head.closeSubpath()
                context.fill(head, with: chamberShading)
                context.stroke(head, with: lineShading, style: strokeStyle)

                var ears = Path()
                ears.move(to: pt(6.5, 7.5))
                ears.addLine(to: pt(3.4, 12.2))
                ears.addLine(to: pt(6.0, 13.8))
                ears.move(to: pt(17.5, 7.5))
                ears.addLine(to: pt(20.6, 12.2))
                ears.addLine(to: pt(18.0, 13.8))
                context.stroke(ears, with: lineShading, style: fineStroke)

                context.fill(Path(ellipseIn: rect(10.6, 14.8, 2.8, 2.2)), with: solidAccent)

            case "paw":
                // Smooth geometric paw pad + 4 symmetrical toe beans
                var pad = Path()
                pad.move(to: pt(12.0, 11.4))
                pad.addCurve(to: pt(17.6, 17.6), control1: pt(16.0, 11.4), control2: pt(18.5, 15.2))
                pad.addCurve(to: pt(6.4, 17.6), control1: pt(16.6, 20.2), control2: pt(7.4, 20.2))
                pad.addCurve(to: pt(12.0, 11.4), control1: pt(5.5, 15.2), control2: pt(8.0, 11.4))
                pad.closeSubpath()
                context.fill(pad, with: chamberShading)
                context.stroke(pad, with: lineShading, style: strokeStyle)

                for (bx, by) in [(5.0, 8.6), (8.8, 5.2), (13.0, 5.2), (16.8, 8.6)] {
                    let bean = Path(ellipseIn: rect(bx, by, 2.3, 3.0))
                    context.fill(bean, with: solidAccent)
                }

            case "desk":
                // Ultrawide display + minimalist stand + keyboard bar
                let screen = rrect(3.0, 3.8, 18.0, 10.6, 2.4)
                context.fill(screen, with: chamberShading)
                context.stroke(screen, with: lineShading, style: strokeStyle)

                var stand = Path()
                stand.move(to: pt(12.0, 14.4))
                stand.addLine(to: pt(12.0, 17.5))
                stand.move(to: pt(8.5, 17.5))
                stand.addLine(to: pt(15.5, 17.5))
                stand.move(to: pt(6.0, 20.4))
                stand.addLine(to: pt(18.0, 20.4))
                context.stroke(stand, with: lineShading, style: strokeStyle)

            case "wave":
                // Modern Kanagawa geometric cresting wave inside circle
                let ring = Path(ellipseIn: rect(3.0, 3.0, 18.0, 18.0))
                context.fill(ring, with: chamberShading)
                context.stroke(ring, with: lineShading, style: strokeStyle)

                var crest = Path()
                crest.move(to: pt(4.2, 14.2))
                crest.addCurve(to: pt(14.5, 9.2), control1: pt(6.8, 8.5), control2: pt(11.8, 6.8))
                crest.addCurve(to: pt(19.8, 14.8), control1: pt(13.0, 13.2), control2: pt(16.8, 16.2))
                context.stroke(crest, with: solidAccent, style: strokeStyle)

            case "pill":
                // Sleek 45-degree two-tone capsule
                context.drawLayer { layer in
                    layer.translateBy(x: ox + 12 * s, y: oy + 12 * s)
                    layer.rotate(by: .degrees(-42))
                    let cap = Path(roundedRect: CGRect(x: -4.2 * s, y: -8.6 * s, width: 8.4 * s, height: 17.2 * s), cornerRadius: 4.2 * s, style: .continuous)
                    let topHalf = Path(CGRect(x: -4.2 * s, y: -8.6 * s, width: 8.4 * s, height: 8.6 * s))
                    layer.drawLayer { sub in
                        sub.clip(to: cap)
                        sub.fill(topHalf, with: chamberShading)
                    }
                    layer.stroke(cap, with: lineShading, style: strokeStyle)
                    var mid = Path()
                    mid.move(to: CGPoint(x: -4.0 * s, y: 0))
                    mid.addLine(to: CGPoint(x: 4.0 * s, y: 0))
                    layer.stroke(mid, with: lineShading, style: fineStroke)
                }

            case "cart":
                // Streamlined modern market tote / basket
                var bag = Path()
                bag.move(to: pt(4.5, 9.0))
                bag.addLine(to: pt(19.5, 9.0))
                bag.addLine(to: pt(17.6, 19.8))
                bag.addLine(to: pt(6.4, 19.8))
                bag.closeSubpath()
                context.fill(bag, with: chamberShading)
                context.stroke(bag, with: lineShading, style: strokeStyle)

                var handles = Path()
                handles.move(to: pt(8.5, 9.0))
                handles.addCurve(to: pt(15.5, 9.0), control1: pt(8.5, 3.6), control2: pt(15.5, 3.6))
                context.stroke(handles, with: lineShading, style: strokeStyle)

            case "mail":
                // Precision geometric envelope with chevron flap
                let env = rrect(3.0, 5.5, 18.0, 13.0, 2.8)
                context.fill(env, with: chamberShading)
                context.stroke(env, with: lineShading, style: strokeStyle)

                var flap = Path()
                flap.move(to: pt(4.0, 7.0))
                flap.addLine(to: pt(12.0, 13.0))
                flap.addLine(to: pt(20.0, 7.0))
                context.stroke(flap, with: solidAccent, style: strokeStyle)

            case "bolt":
                // Chiseled high-voltage geometric lightning prism
                var bolt = Path()
                bolt.move(to: pt(13.4, 2.5))
                bolt.addLine(to: pt(5.4, 13.2))
                bolt.addLine(to: pt(11.6, 13.2))
                bolt.addLine(to: pt(10.6, 21.5))
                bolt.addLine(to: pt(18.6, 10.8))
                bolt.addLine(to: pt(12.4, 10.8))
                bolt.closeSubpath()
                context.fill(bolt, with: chamberShading)
                context.stroke(bolt, with: lineShading, style: strokeStyle)

            case "heart":
                // Smooth sculpted geometric heart
                var heart = Path()
                heart.move(to: pt(12.0, 20.2))
                heart.addCurve(to: pt(3.2, 9.2), control1: pt(7.2, 16.8), control2: pt(3.2, 13.2))
                heart.addCurve(to: pt(12.0, 6.8), control1: pt(3.2, 4.6), control2: pt(9.4, 3.8))
                heart.addCurve(to: pt(20.8, 9.2), control1: pt(14.6, 3.8), control2: pt(20.8, 4.6))
                heart.addCurve(to: pt(12.0, 20.2), control1: pt(20.8, 13.2), control2: pt(16.8, 16.8))
                heart.closeSubpath()
                context.fill(heart, with: chamberShading)
                context.stroke(heart, with: lineShading, style: strokeStyle)

            case "terminal_home":
                // Architectural minimal house housing a crisp >_ prompt
                var home = Path()
                home.move(to: pt(3.5, 11.2))
                home.addLine(to: pt(12.0, 3.6))
                home.addLine(to: pt(20.5, 11.2))
                home.move(to: pt(5.6, 9.6))
                home.addLine(to: pt(5.6, 19.8))
                home.addLine(to: pt(18.4, 19.8))
                home.addLine(to: pt(18.4, 9.6))
                context.fill(rrect(5.8, 10.0, 12.4, 9.6, 1.5), with: chamberShading)
                context.stroke(home, with: lineShading, style: strokeStyle)

                var pr = Path()
                pr.move(to: pt(9.0, 12.6))
                pr.addLine(to: pt(11.4, 14.6))
                pr.addLine(to: pt(9.0, 16.6))
                pr.move(to: pt(12.8, 16.6))
                pr.addLine(to: pt(15.4, 16.6))
                context.stroke(pr, with: solidAccent, style: fineStroke)

            default: // "spark" — 4-point modern geometric star-prism + orbital diamond
                var star = Path()
                star.move(to: pt(11.0, 2.8))
                star.addQuadCurve(to: pt(19.2, 11.0), control: pt(11.8, 10.2))
                star.addQuadCurve(to: pt(11.0, 19.2), control: pt(11.8, 11.8))
                star.addQuadCurve(to: pt(2.8, 11.0), control: pt(10.2, 11.8))
                star.addQuadCurve(to: pt(11.0, 2.8), control: pt(10.2, 10.2))
                star.closeSubpath()
                context.fill(star, with: chamberShading)
                context.stroke(star, with: lineShading, style: strokeStyle)

                var mini = Path()
                mini.move(to: pt(19.0, 15.6))
                mini.addLine(to: pt(21.4, 18.0))
                mini.addLine(to: pt(19.0, 20.4))
                mini.addLine(to: pt(16.6, 18.0))
                mini.closeSubpath()
                context.fill(mini, with: solidAccent)
            }
        }
        .frame(width: glyphSize, height: glyphSize)
        .accessibilityHidden(true)
    }
}

/// Backward-compatible wrapper so any existing call sites seamlessly render sleek vector glyphs instead of 8-bit pixels.
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
        StylizedVectorGlyphView(
            glyphKey: glyphKey,
            primaryColor: color,
            glyphSize: pixelSize * 11.2
        )
    }
}

// MARK: - Unified Theme-Aware Chore & Room Icon Container

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
            case .omarchyPixelHUD: return max(6, size * 0.22)
            case .minimalOutline: return size * 0.26
            case .softMedallion: return size * 0.30
            case .boldBadge: return size * 0.25
            case .autoTheme: return size * 0.27
            }
        }()
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        ZStack {
            switch style {
            case .omarchyPixelHUD:
                // Anodized dark/tonal glass tile + 45deg dual-gradient precision rim + subtle ambient glow
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.cardElevatedSurface,
                                theme.canvasSecondary.opacity(theme.isDark ? 0.96 : 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        shape
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tint.opacity(theme.isDark ? 0.22 : 0.14),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 1,
                                    endRadius: size * 0.85
                                )
                            )
                    }
                    .overlay {
                        shape
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(0.75),
                                        theme.accentSecondary.opacity(0.42)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.15
                            )
                    }

            case .minimalOutline:
                shape
                    .fill(tint.opacity(theme.isDark ? 0.10 : 0.07))
                    .overlay {
                        shape
                            .strokeBorder(tint.opacity(0.28), lineWidth: 1.0)
                    }

            case .boldBadge:
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                tint,
                                tint.opacity(0.84)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                    .overlay {
                        shape
                            .strokeBorder(theme.borderInk, lineWidth: theme.usesHardOffsetShadow ? 1.6 : 1.0)
                    }

            case .softMedallion, .autoTheme:
                // Duotone layered glass medallion
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(theme.isDark ? 0.24 : 0.17),
                                tint.opacity(theme.isDark ? 0.10 : 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        shape
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDark ? 0.16 : 0.65),
                                        tint.opacity(0.22)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.95
                            )
                    }
            }

            glyphContent(for: style)
        }
        .frame(width: size, height: size)
        .shadow(
            color: style == .omarchyPixelHUD && theme.isDark
                ? tint.opacity(0.14)
                : Color.clear,
            radius: 4,
            x: 0,
            y: 1.5
        )
    }

    @ViewBuilder
    private func glyphContent(for style: IconStylePreference) -> some View {
        let fgColor: Color = (style == .boldBadge) ? .white : tint
        let secColor: Color = (style == .boldBadge) ? Color.white.opacity(0.85) : theme.accentSecondary

        if iconSymbol.hasPrefix("emoji:") {
            let emoji = String(iconSymbol.dropFirst("emoji:".count))
            Text(emoji)
                .font(.system(size: size * 0.48))
        } else if iconSymbol.hasPrefix("omarchy:") {
            let key = String(iconSymbol.dropFirst("omarchy:".count))
            StylizedVectorGlyphView(
                glyphKey: key,
                primaryColor: fgColor,
                secondaryColor: secColor,
                glyphSize: size * 0.56
            )
        } else if style == .omarchyPixelHUD,
                  let mappedKey = ChoreIconCatalog.mappedOmarchyGlyphKey(for: iconSymbol) {
            StylizedVectorGlyphView(
                glyphKey: mappedKey,
                primaryColor: fgColor,
                secondaryColor: secColor,
                glyphSize: size * 0.56
            )
        } else {
            Image(systemName: iconSymbol)
                .symbolRenderingMode(.hierarchical)
                .font(.system(
                    size: size * 0.44,
                    weight: style == .minimalOutline ? .medium : .semibold
                ))
                .foregroundStyle(
                    style == .boldBadge
                        ? AnyShapeStyle(Color.white)
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [fgColor, fgColor.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
    }
}
