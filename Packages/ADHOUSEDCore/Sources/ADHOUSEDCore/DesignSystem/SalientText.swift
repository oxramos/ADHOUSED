import Foundation
import SwiftUI

// MARK: - High-Salience / Bionic Reading Formatter & Dimensional Text View

public enum SalientTextFormatter {
    /// Generates an `AttributedString` where the leading fixation stem (~40% of letters) of each word
    /// is bolded so readers anchor onto word shapes quickly without skimming drift.
    public static func format(
        _ text: String,
        bionicEnabled: Bool,
        baseFont: Font = .headline
    ) -> AttributedString {
        guard bionicEnabled, !text.isEmpty else {
            return AttributedString(text)
        }

        var output = AttributedString()
        let parts = text.split(separator: " ", omittingEmptySubsequences: false)

        for (index, rawWord) in parts.enumerated() {
            if index > 0 {
                output.append(AttributedString(" "))
            }
            let word = String(rawWord)
            guard !word.isEmpty else { continue }

            let letterIndices = word.indices.filter { word[$0].isLetter || word[$0].isNumber }
            guard !letterIndices.isEmpty else {
                output.append(AttributedString(word))
                continue
            }

            let boldLetterCount = max(1, Int(ceil(Double(letterIndices.count) * 0.42)))
            let cutoffCharIndex = letterIndices[min(letterIndices.count - 1, boldLetterCount - 1)]
            let splitAfter = word.index(after: cutoffCharIndex)

            var prefixAttr = AttributedString(String(word[..<splitAfter]))
            prefixAttr.inlinePresentationIntent = .stronglyEmphasized

            let suffixAttr = AttributedString(String(word[splitAfter...]))
            output.append(prefixAttr)
            output.append(suffixAttr)
        }

        return output
    }
}

public struct SalientText: View {
    @Environment(\.adhousedTheme) private var theme
    public let text: String
    public var bionicEnabled: Bool?
    public var style: ThemeTextStyle?
    public var font: Font
    public var color: Color?
    public var lineLimit: Int?

    public init(
        _ text: String,
        bionicEnabled: Bool? = nil,
        style: ThemeTextStyle? = nil,
        font: Font = .headline,
        color: Color? = nil,
        lineLimit: Int? = nil
    ) {
        self.text = text
        self.bionicEnabled = bionicEnabled
        self.style = style
        self.font = font
        self.color = color
        self.lineLimit = lineLimit
    }

    public var body: some View {
        let activeBionic = bionicEnabled ?? ADHOUSEDPreferences.shared.bionicReadingEnabled
        let resolvedFont = style.map { theme.font($0) } ?? font
        let baseTracking = style.map { theme.tracking(for: $0) } ?? (theme.fontDesign == .monospaced ? -0.15 : 0)

        Text(SalientTextFormatter.format(text, bionicEnabled: activeBionic, baseFont: resolvedFont))
            .font(resolvedFont)
            .fontDesign(style == nil ? theme.fontDesign : nil)
            .tracking(baseTracking + (activeBionic ? 0.15 : 0))
            .foregroundStyle(color ?? theme.primaryInk)
            .shadow(
                color: .black.opacity(theme.isDark ? 0.28 : 0.0),
                radius: 0.8,
                x: 0,
                y: 0.8
            )
            .lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
    }
}
