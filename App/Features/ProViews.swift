import SwiftUI
import TidemarkCore
import UIKit

extension ProFeature: Identifiable {
    public var id: String { rawValue }
}

/// Small lock shown next to anything that needs Pro.
struct ProBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.fill")
            Text(verbatim: "Pro")
        }
        .font(.caption2.weight(.bold))
        .padding(.horizontal, 6).padding(.vertical, 3)
        .foregroundStyle(Theme.accentInk)
        .background(Theme.tint, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Needs Pro"))
    }
}

/// 4, 8, 12 weeks free; 6 and 12 months with Pro. A locked option opens the paywall instead.
struct RangePicker: View {
    @Binding var selection: HistoryRange
    let isPro: Bool
    let onLocked: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { buttons }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) { buttons }
        }
    }

    private var buttons: some View {
        ForEach(HistoryRange.allCases) { range in
            let selected = range == selection
            let locked = range.needsPro && !isPro
            Button {
                if locked { onLocked() } else {
                    selection = range
                    UsageAnalytics.shared.log(.rangeSelected, .range(range))
                }
            } label: {
                HStack(spacing: 3) {
                    if locked { Image(systemName: "lock.fill").font(.caption2) }
                    Text(verbatim: label(range))
                        .font(.footnote.weight(selected ? .bold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 2)
                .foregroundStyle(locked ? Theme.muted : Theme.ink)
                .background(selected ? Theme.tint : Theme.card, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Theme.accentInk : Theme.chipBorder, lineWidth: selected ? 2 : 1))
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityHint(locked ? Text("Needs Pro") : Text(verbatim: ""))
        }
    }

    private func label(_ range: HistoryRange) -> String {
        if let months = range.months { return String(localized: "\(months) months") }
        return String(localized: "\(range.weeks) weeks")
    }
}

/// Applies the chosen theme (Pro) to the whole app. Changing it rebuilds the view tree, so every
/// color is read again; the selected tab lives in AppModel and survives.
struct ThemedRoot: View {
    @Environment(AppModel.self) private var model
    @AppStorage("appearance.theme") private var themeRaw = AppearanceTheme.teal.rawValue

    var body: some View {
        let theme = model.isPro ? AppearanceTheme(rawValue: themeRaw) ?? .teal : .teal
        let _ = Theme.palette = Palette.of(theme)
        RootView()
            .id(theme)
            .tint(Theme.accent)
            .task(id: model.subscription.hasLoaded ? model.isPro : nil) {
                // Pro ended: go back to the standard icon. Nothing else changes; all data stays.
                guard model.subscription.hasLoaded, !model.isPro,
                      UIApplication.shared.supportsAlternateIcons, UIApplication.shared.alternateIconName != nil else { return }
                try? await UIApplication.shared.setAlternateIconName(nil)
            }
    }
}

// MARK: Appearance

struct AppearanceView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("appearance.theme") private var themeRaw = AppearanceTheme.teal.rawValue
    @State private var icon = AppIconChoice(assetName: UIApplication.shared.alternateIconName)
    @State private var paywall: ProFeature?

    var body: some View {
        Page {
            ScreenHeader(title: "Theme and app icon")
            if !model.isPro {
                Text("Themes and app icons come with Pro.").foregroundStyle(Theme.secondary)
            }

            SectionLabel(text: "Theme")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(AppearanceTheme.allCases, id: \.self) { theme in
                    let selected = (model.isPro ? AppearanceTheme(rawValue: themeRaw) ?? .teal : .teal) == theme
                    Button { choose(theme) } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                ForEach([Palette.of(theme).mild, Palette.of(theme).moderate, Palette.of(theme).severe], id: \.light) { pair in
                                    RoundedRectangle(cornerRadius: 4).fill(Theme.dynamic(pair)).frame(height: 22)
                                }
                            }
                            HStack {
                                Text(verbatim: name(theme)).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                                Spacer()
                                if theme != .teal && !model.isPro { ProBadge() }
                                if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.dynamic(Palette.of(theme).accent)) }
                            }
                        }
                        .padding(12)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Theme.accentInk : Theme.border, lineWidth: selected ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }

            if UIApplication.shared.supportsAlternateIcons {
                SectionLabel(text: "App icon")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(AppIconChoice.allCases, id: \.self) { choice in
                        let selected = icon == choice
                        Button { setIcon(choice) } label: {
                            VStack(spacing: 6) {
                                Image(previewName(choice))
                                    .resizable().scaledToFit()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Theme.accentInk : Theme.border, lineWidth: selected ? 3 : 1))
                                HStack(spacing: 3) {
                                    if choice != .standard && !model.isPro { Image(systemName: "lock.fill").font(.caption2) }
                                    Text(verbatim: iconName(choice)).font(.caption)
                                }
                                .foregroundStyle(Theme.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $paywall) { PaywallView(feature: $0) }
        .analyticsScreen(.appearance)
    }

    private func choose(_ theme: AppearanceTheme) {
        guard theme == .teal || model.isPro else { return openPaywall() }
        themeRaw = theme.rawValue
        UsageAnalytics.shared.log(.themeChanged, .theme(theme))
    }

    private func setIcon(_ choice: AppIconChoice) {
        guard choice == .standard || model.isPro else { return openPaywall() }
        Task {
            try? await UIApplication.shared.setAlternateIconName(choice.assetName)
            icon = AppIconChoice(assetName: UIApplication.shared.alternateIconName)
            UsageAnalytics.shared.log(.iconChanged, .icon(icon))
        }
    }

    private func openPaywall() {
        UsageAnalytics.shared.log(.proFeatureTapped, .feature(.appearance))
        paywall = .appearance
    }

    private func name(_ theme: AppearanceTheme) -> String {
        switch theme {
        case .teal: String(localized: "Tide")
        case .plum: String(localized: "Plum")
        case .ocean: String(localized: "Ocean")
        case .forest: String(localized: "Forest")
        }
    }

    private func iconName(_ choice: AppIconChoice) -> String {
        switch choice {
        case .standard: String(localized: "Tide")
        case .plum: String(localized: "Plum")
        case .ocean: String(localized: "Ocean")
        case .forest: String(localized: "Forest")
        case .night: String(localized: "Night")
        }
    }

    private func previewName(_ choice: AppIconChoice) -> String {
        switch choice {
        case .standard: "IconPreview-Teal"
        case .plum: "IconPreview-Plum"
        case .ocean: "IconPreview-Ocean"
        case .forest: "IconPreview-Forest"
        case .night: "IconPreview-Night"
        }
    }
}

// MARK: Since your last visit (report page 2)

/// Second report page (Pro): the user's own numbers before and after a date she chose.
/// Numbers only. It never says better or worse, and never says why anything changed.
struct ComparisonPage: View {
    let profile: Profile
    let comparison: PeriodComparison

    var body: some View {
        let size = profile.region.paper.size
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Before and after \(comparison.split.medium)").font(.system(size: 18, weight: .bold))
                Text("\(range(comparison.before)) compared with \(range(comparison.after)), equal lengths.")
                    .font(.system(size: 10))
                Text("Recorded by me in the Tidemark app.").font(.system(size: 9)).foregroundStyle(Color.gray)
                Divider()
            }

            block("My daily ratings") {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 3) {
                    GridRow {
                        Text("Symptom").bold()
                        Text("Average before (0–3)").bold()
                        Text("Average after (0–3)").bold()
                        Text("Days present before").bold()
                        Text("Days present after").bold()
                    }
                    .font(.system(size: 9))
                    ForEach(comparison.rows.prefix(14), id: \.symptomID) { row in
                        GridRow {
                            Text(verbatim: Symptom.label(for: row.symptomID))
                            Text(verbatim: average(row.before))
                            Text(verbatim: average(row.after))
                            Text(verbatim: "\(row.daysPresentBefore)")
                            Text(verbatim: "\(row.daysPresentAfter)")
                        }
                        .font(.system(size: 10))
                    }
                }
                Text("0 none, 1 mild, 2 moderate, 3 severe. Averages of the days I rated each symptom.")
                    .font(.system(size: 8)).foregroundStyle(Color.gray)
            }

            block("Other numbers") {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 3) {
                    GridRow {
                        Text(verbatim: "")
                        Text("Before").bold()
                        Text("After").bold()
                    }
                    .font(.system(size: 9))
                    statRow("Days logged", comparison.before.daysLogged, comparison.after.daysLogged)
                    statRow("Days symptoms affected me quite a bit or a lot", comparison.before.hardImpactDays, comparison.after.hardImpactDays)
                    statRow("Hot flushes and night sweats logged", comparison.before.quickLogs, comparison.after.quickLogs)
                    statRow("Days with any bleeding", comparison.before.bleedingDays, comparison.after.bleedingDays)
                    GridRow {
                        Text(LocalizedStringKey(Questionnaire.scaleName))
                        Text(verbatim: comparison.before.questionnaire.map { "\($0) / \(Questionnaire.maxScore)" } ?? "–")
                        Text(verbatim: comparison.after.questionnaire.map { "\($0) / \(Questionnaire.maxScore)" } ?? "–")
                    }
                    .font(.system(size: 10))
                }
            }

            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 2) {
                Divider()
                Text("These are the numbers I recorded. They do not show why anything changed.")
                Text("Self-reported symptom record. It is not a diagnosis and does not suggest any treatment.")
                Text("Made with Tidemark on \(DayKey.today.medium).")
            }
            .font(.system(size: 8))
            .foregroundStyle(Color.gray)
        }
        .padding(36)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .foregroundStyle(Color.black)
        .background(Color.white)
        .environment(\.colorScheme, .light)
        .dynamicTypeSize(.large)
    }

    private func range(_ side: PeriodComparison.Side) -> String {
        String(localized: "\(side.from.medium) to \(side.to.medium)")
    }

    private func average(_ value: Double?) -> String {
        value.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "–"
    }

    private func statRow(_ title: LocalizedStringKey, _ before: Int, _ after: Int) -> some View {
        GridRow {
            Text(title)
            Text(verbatim: "\(before)")
            Text(verbatim: "\(after)")
        }
        .font(.system(size: 10))
    }

    private func block<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 11, weight: .bold)).foregroundStyle(Color(red: 0.055, green: 0.43, blue: 0.42))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
