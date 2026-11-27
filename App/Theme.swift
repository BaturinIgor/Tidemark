import SwiftUI
import TidemarkCore
import UIKit

/// Colors and components from the palette board in the mockups. Every color has a dark-mode pair.
enum Theme {
    /// Pro: Settings › Appearance. Read on every redraw; RootView rebuilds the tree when it changes.
    nonisolated(unsafe) static var palette = Palette.teal

    static var accent: Color { dynamic(palette.accent) }
    static var accentInk: Color { dynamic(palette.accentInk) }
    static var onAccent: Color { dynamic(palette.onAccent) }
    static var tint: Color { dynamic(palette.tint) }
    static let ink = dynamic(light: 0x1B1F23, dark: 0xE8ECEA)
    static let secondary = dynamic(light: 0x3D4750, dark: 0xC3CBC7)
    static let muted = dynamic(light: 0x4A5560, dark: 0xA9B3AE)
    static let background = dynamic(light: 0xF6F7F5, dark: 0x111416)
    static let card = dynamic(light: 0xFFFFFF, dark: 0x1B2024)
    static let border = dynamic(light: 0xDDE3E0, dark: 0x2A3136)
    static let line = dynamic(light: 0xEEF1EF, dark: 0x242A2E)
    static let chipBorder = dynamic(light: 0xC9D0CC, dark: 0x3A4348)
    static let warnBackground = dynamic(light: 0xFFF4EC, dark: 0x2E221A)
    static let warnBorder = dynamic(light: 0xF1D3BE, dark: 0x5A3B26)
    static let danger = dynamic(light: 0xA3301A, dark: 0xF08A70)
    static let bleeding = dynamic(light: 0xC2562F, dark: 0xE07A52)
    static let bleedingLight = dynamic(light: 0xE9B6A3, dark: 0x6B3A28)

    /// Severity ramp: none, mild, moderate, severe. In dark mode harder days are brighter.
    static func fill(_ severity: Severity) -> Color {
        switch severity {
        case .none: dynamic(light: 0xF0F3F1, dark: 0x1B2024)
        case .mild: dynamic(palette.mild)
        case .moderate: dynamic(palette.moderate)
        case .severe: dynamic(palette.severe)
        }
    }

    static func onFill(_ severity: Severity) -> Color {
        switch severity {
        case .none: ink
        case .mild: dynamic(palette.onMild)
        case .moderate: dynamic(palette.onModerate)
        case .severe: dynamic(palette.onSevere)
        }
    }

    static func dynamic(_ pair: Palette.Pair) -> Color { dynamic(light: pair.light, dark: pair.dark) }

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

/// Accent colors and the severity ramp for one theme. Text on accent and on every fill keeps at least
/// 4.5:1 contrast in light and dark mode.
struct Palette {
    struct Pair { let light: UInt32; let dark: UInt32 }

    let accent: Pair, accentInk: Pair, onAccent: Pair, tint: Pair
    let mild: Pair, moderate: Pair, severe: Pair
    let onMild: Pair, onModerate: Pair, onSevere: Pair

    static let teal = Palette(
        accent: .init(light: 0x0E6E6B, dark: 0x5FA9A3), accentInk: .init(light: 0x0A4F4D, dark: 0x8CC7C1),
        onAccent: .init(light: 0xFFFFFF, dark: 0x08201F), tint: .init(light: 0xE3F0EE, dark: 0x16302E),
        mild: .init(light: 0xCFE5E2, dark: 0x24433F), moderate: .init(light: 0x5FA9A3, dark: 0x3E8580),
        severe: .init(light: 0x0E6E6B, dark: 0x5FA9A3),
        onMild: .init(light: 0x0A3A39, dark: 0xCFE5E2), onModerate: .init(light: 0x08201F, dark: 0xFFFFFF),
        onSevere: .init(light: 0xFFFFFF, dark: 0x08201F))

    static let plum = Palette(
        accent: .init(light: 0x7B3F6E, dark: 0xC68BB8), accentInk: .init(light: 0x5A2A50, dark: 0xDDB0D2),
        onAccent: .init(light: 0xFFFFFF, dark: 0x2A0F24), tint: .init(light: 0xF3E7F0, dark: 0x36202F),
        mild: .init(light: 0xEBD3E4, dark: 0x4A2A42), moderate: .init(light: 0xC68BB8, dark: 0x8E5482),
        severe: .init(light: 0x7B3F6E, dark: 0xC68BB8),
        onMild: .init(light: 0x3F1A37, dark: 0xEBD3E4), onModerate: .init(light: 0x2A0F24, dark: 0xFFFFFF),
        onSevere: .init(light: 0xFFFFFF, dark: 0x2A0F24))

    static let ocean = Palette(
        accent: .init(light: 0x245C93, dark: 0x7FB0E0), accentInk: .init(light: 0x1A4470, dark: 0xA9CBEE),
        onAccent: .init(light: 0xFFFFFF, dark: 0x0A1C30), tint: .init(light: 0xE4EEF8, dark: 0x172636),
        mild: .init(light: 0xCFE0F2, dark: 0x22364C), moderate: .init(light: 0x7FB0E0, dark: 0x3F6E9E),
        severe: .init(light: 0x245C93, dark: 0x7FB0E0),
        onMild: .init(light: 0x0E2A47, dark: 0xCFE0F2), onModerate: .init(light: 0x0A1C30, dark: 0xFFFFFF),
        onSevere: .init(light: 0xFFFFFF, dark: 0x0A1C30))

    static let forest = Palette(
        accent: .init(light: 0x3D6B2F, dark: 0x9CC48A), accentInk: .init(light: 0x2C5022, dark: 0xBEDBAF),
        onAccent: .init(light: 0xFFFFFF, dark: 0x12210C), tint: .init(light: 0xE8F1E3, dark: 0x1C2B17),
        mild: .init(light: 0xD7E8CE, dark: 0x2B4223), moderate: .init(light: 0x9CC48A, dark: 0x4E7B3E),
        severe: .init(light: 0x3D6B2F, dark: 0x9CC48A),
        onMild: .init(light: 0x1C3314, dark: 0xD7E8CE), onModerate: .init(light: 0x12210C, dark: 0xFFFFFF),
        onSevere: .init(light: 0xFFFFFF, dark: 0x12210C))

    static func of(_ theme: AppearanceTheme) -> Palette {
        switch theme {
        case .teal: teal
        case .plum: plum
        case .ocean: ocean
        case .forest: forest
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: Components

struct Card<Content: View>: View {
    var spacing: CGFloat = 10
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border))
    }
}

struct WarningCard<Content: View>: View {
    var systemImage = "exclamationmark.icloud"
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage).foregroundStyle(Theme.danger).font(.title3)
            VStack(alignment: .leading, spacing: 8) { content }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.warnBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.warnBorder))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: height)
            .foregroundStyle(Theme.onAccent)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct OutlineButtonStyle: ButtonStyle {
    var height: CGFloat = 48

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: height)
            .foregroundStyle(Theme.accentInk)
            .background(configuration.isPressed ? Theme.tint : Color.clear, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: 1.5))
    }
}

/// Four buttons for None, Mild, Moderate, Severe. Two columns at the largest text sizes.
struct SeverityPicker: View {
    @Binding var value: Severity?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let columns = typeSize.isAccessibilitySize ? 2 : 4
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
            ForEach(Severity.allCases, id: \.self) { level in
                let selected = value == level
                Button {
                    value = level
                } label: {
                    Text(verbatim: typeSize.isAccessibilitySize || level != .moderate ? level.label : String(localized: "Mod.", comment: "Short for Moderate on a narrow button"))
                        .font(.footnote.weight(selected ? .bold : .regular))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(selected ? Theme.onFill(level) : Theme.secondary)
                        .background(selected ? Theme.fill(level) : Theme.card, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Theme.accentInk : Theme.chipBorder, lineWidth: selected ? 2 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(level.label)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

/// A row of equal buttons for a small set of options (impact, bleeding).
struct OptionRow<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button { selection = option } label: {
                    Text(verbatim: label(option))
                        .font(.footnote.weight(selected ? .bold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(Theme.ink)
                        .background(selected ? Theme.tint : Theme.card, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Theme.accentInk : Theme.chipBorder, lineWidth: selected ? 2 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

extension View {
    /// A "Done" button above the keyboard and swipe-down to hide it. Number pads and multi-line fields
    /// have no other way to close the keyboard.
    func keyboardDismissable() -> some View {
        scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                }
            }
    }
}

struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    /// Titles come from already-localized labels (symptoms, factors, decisions).
    var body: some View {
        Button(action: action) {
            // Always as wide as the selected chip, so choosing one never re-wraps the row.
            ZStack {
                Text(verbatim: "✓ \(title)").font(.subheadline.weight(.semibold)).hidden().accessibilityHidden(true)
                Text(verbatim: selected ? "✓ \(title)" : title)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
            }
                .padding(.horizontal, 14)
                .frame(minHeight: 40)
                .foregroundStyle(selected ? Theme.accentInk : Theme.ink)
                .background(selected ? Theme.tint : Theme.card, in: Capsule())
                .overlay(Capsule().stroke(selected ? Theme.accentInk : Theme.chipBorder, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Like `Text`, a string literal is looked up in the string catalog and a `String` value is shown as is.
struct ScreenHeader: View {
    let title: Text
    var subtitle: Text?

    init(title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.title = Text(title)
        self.subtitle = subtitle.map { Text($0) }
    }

    /// For text that is already localized or typed by the user (a medicine name). Plain literals go through
    /// the LocalizedStringKey init above; without the `verbatim:` label Swift picked this one for them.
    init(verbatim title: String, subtitle: String? = nil) {
        self.title = Text(verbatim: title)
        self.subtitle = subtitle.map { Text(verbatim: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let subtitle {
                subtitle.font(.subheadline).foregroundStyle(Theme.muted)
            }
            title.font(.largeTitle.bold()).foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionLabel: View {
    let text: Text

    init(text: LocalizedStringKey) { self.text = Text(text) }
    @_disfavoredOverload
    init(text: String) { self.text = Text(verbatim: text) }

    var body: some View {
        text.font(.footnote.weight(.semibold)).foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

struct Disclaimer: View {
    var text: LocalizedStringKey = "This app records what you report. It does not diagnose or give medical advice."
    var body: some View {
        Text(text).font(.caption).foregroundStyle(Theme.muted)
    }
}

/// Scrollable page with the app background, used by every screen.
struct Page<Content: View>: View {
    var spacing: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) { content }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

extension DayKey {
    /// "Wed 18 Nov"
    var short: String {
        referenceDate.formatted(Date.FormatStyle(timeZone: TimeZone(identifier: "UTC")!).weekday(.abbreviated).day().month(.abbreviated))
    }

    /// "18 Nov 2026"
    var medium: String {
        referenceDate.formatted(Date.FormatStyle(timeZone: TimeZone(identifier: "UTC")!).day().month(.abbreviated).year())
    }

    static var today: DayKey { DayKey(Date()) }
}
