import SwiftUI
import ADHOUSEDCore

struct ChoreIconPickerView: View {
    @Environment(\.adhousedTheme) private var theme
    @Binding var selectedIcon: String
    var accentTint: Color

    @State private var selectedPack: ChoreIconPack = .homeAndRooms
    @State private var isExpandedAllPacks: Bool = false
    @State private var didInitPack: Bool = false

    private let quickCuratedIDs: [String] = [
        "sparkles", "dishwasher.fill", "washer.fill", "bed.double.fill",
        "trash.fill", "shower.fill", "pawprint.fill", "leaf.fill",
        "omarchy:ghost", "omarchy:arch", "omarchy:dishes", "omarchy:cat"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ChoreIconBadgeView(
                    iconSymbol: selectedIcon,
                    tint: accentTint,
                    size: 40
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Icon Style")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(theme.secondaryInk)
                    Text(currentIconLabel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        isExpandedAllPacks.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isExpandedAllPacks ? "chevron.up" : "square.grid.3x3.fill")
                        Text(isExpandedAllPacks ? "Fewer Icons" : "Browse All Icons")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accentPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(theme.accentPrimary.opacity(0.14)))
                }
                .buttonStyle(.plain)
            }

            if !isExpandedAllPacks {
                // Quick row (adapts automatically to Omarchy themes)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(defaultQuickChoices, id: \.self) { sym in
                            iconTileButton(id: sym, label: nil)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else {
                // Full Multi-Pack Categorized Icon Browser
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(ChoreIconPack.allCases) { pack in
                            let active = selectedPack == pack
                            Button {
                                HapticsEngine.shared.playMechanicalTap()
                                selectedPack = pack
                            } label: {
                                Text(pack.title)
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(active ? theme.accentPrimary : theme.canvasSecondary)
                                    )
                                    .foregroundStyle(active ? theme.onAccentPrimary : theme.primaryInk)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                let choices = ChoreIconCatalog.choices(for: selectedPack)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                    spacing: 8
                ) {
                    ForEach(choices) { choice in
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            selectedIcon = choice.id
                        } label: {
                            VStack(spacing: 5) {
                                ChoreIconBadgeView(
                                    iconSymbol: choice.id,
                                    tint: selectedIcon == choice.id ? theme.accentPrimary : accentTint,
                                    size: 36,
                                    styleOverride: selectedPack == .omarchyPixel ? .omarchyPixelHUD : nil
                                )
                                Text(choice.label)
                                    .font(.system(size: 10, weight: .semibold, design: theme.fontDesign))
                                    .foregroundStyle(selectedIcon == choice.id ? theme.accentPrimary : theme.secondaryInk)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 7 : 11, style: .continuous)
                                    .fill(selectedIcon == choice.id ? theme.accentPrimary.opacity(0.15) : theme.canvasSecondary)
                            )
                            .overlay {
                                if selectedIcon == choice.id {
                                    RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 7 : 11, style: .continuous)
                                        .strokeBorder(theme.accentPrimary, lineWidth: 1.4)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onAppear {
            guard !didInitPack else { return }
            didInitPack = true
            if selectedIcon.hasPrefix("omarchy:") || theme.preset.isOmarchyQuattroStyle || ADHOUSEDPreferences.shared.iconStylePreference == .omarchyPixelHUD {
                selectedPack = .omarchyPixel
            } else if selectedIcon.hasPrefix("emoji:") {
                selectedPack = .expressiveEmoji
            } else if let matched = ChoreIconCatalog.allChoices.first(where: { $0.id == selectedIcon }) {
                selectedPack = matched.pack
            }
        }
    }

    private var defaultQuickChoices: [String] {
        if theme.preset.isOmarchyQuattroStyle || ADHOUSEDPreferences.shared.iconStylePreference == .omarchyPixelHUD {
            return [
                "omarchy:spark", "omarchy:dishes", "omarchy:washer", "omarchy:bed",
                "omarchy:trash", "omarchy:shower", "omarchy:plant", "omarchy:cat",
                "omarchy:desk", "omarchy:ghost", "omarchy:arch", "omarchy:wave"
            ]
        }
        return quickCuratedIDs
    }

    private var currentIconLabel: String {
        if let match = ChoreIconCatalog.allChoices.first(where: { $0.id == selectedIcon }) {
            return "\(match.label) · \(match.pack.title)"
        }
        return "Selected Icon"
    }

    private func iconTileButton(id: String, label: String?) -> some View {
        let isSelected = selectedIcon == id
        return Button {
            HapticsEngine.shared.playMechanicalTap()
            selectedIcon = id
        } label: {
            ChoreIconBadgeView(
                iconSymbol: id,
                tint: isSelected ? theme.accentPrimary : accentTint,
                size: 40
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 7 : 11, style: .continuous)
                        .strokeBorder(theme.accentPrimary, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
