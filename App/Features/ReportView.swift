import StoreKit
import SwiftUI
import TidemarkCore

/// Report tab: locked until a week of data, then the builder. The PDF needs a subscription; the on-screen view does not.
struct ReportView: View {
    @Environment(AppModel.self) private var model
    @State private var range: HistoryRange = .weeks8
    @State private var reason = ""
    @State private var loadedReason = false
    @State private var pdfURL: URL?
    @State private var paywall: ProFeature?
    @AppStorage("report.includeComparison") private var includeComparison = false
    @State private var split: Date?
    @AppStorage("report.showHeatMap") private var showHeatMap = true
    @AppStorage("report.showCycle") private var showCycle = true
    @AppStorage("report.showMedicines") private var showMedicines = true
    @AppStorage("report.showQuestions") private var showQuestions = true

    var body: some View {
        let _ = model.revision
        let checkIns = model.repository.allCheckIns()
        let readiness = ReportReadiness.evaluate(checkIns: checkIns.count, questionnaires: model.repository.questionnaires().count)

        Page {
            ScreenHeader(title: "Report", subtitle: "For your \(region.doctorTerm)")
            switch readiness {
            case .locked(let soFar, let needed):
                locked(soFar: soFar, needed: needed)
            case .ready:
                builder
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDismissable()
        .sheet(item: $paywall) { PaywallView(feature: $0) }
        .onAppear(perform: loadReason)
        .analyticsScreen(.report)
    }

    private var region: Region { model.profile?.region ?? .unitedKingdom }

    private func locked(soFar: Int, needed: Int) -> some View {
        Card {
            Image(systemName: "doc.text.magnifyingglass").font(.largeTitle).foregroundStyle(Theme.accent)
            Text("Your first report is \(needed - soFar) check-ins away").font(.title3.bold())
            ProgressView(value: Double(soFar), total: Double(needed)).tint(Theme.accent)
            Text("\(soFar) of \(needed) days logged")
                .font(.subheadline).foregroundStyle(Theme.muted)
            Text("A week of check-ins shows your \(region.doctorTerm) a pattern, not one bad day. Missed a day? You can fill in the last 3 days from Today.")
                .font(.subheadline).foregroundStyle(Theme.secondary)
        }
    }

    @ViewBuilder
    private var builder: some View {
        Card {
            Text("Period").font(.headline)
            RangePicker(selection: $range, isPro: model.isPro) { lockedTapped(.longHistory) }
            let summary = makeData().summary
            Text("\(summary.daysLogged) of \(summary.daysInRange) days logged")
                .font(.subheadline).foregroundStyle(Theme.muted)
        }

        Card {
            Text("Why are you going?").font(.headline)
            Text("One line at the top of the report, in your words.")
                .font(.subheadline).foregroundStyle(Theme.muted)
            TextField("For example: sleep and mood since spring", text: $reason, axis: .vertical)
                .lineLimit(1...3)
                .padding(12)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                .onChange(of: reason) { _, _ in saveReason() }
        }

        Card(spacing: 4) {
            Text("Include").font(.headline).padding(.bottom, 4)
            Toggle("Day-by-day chart", isOn: $showHeatMap)
            Toggle("Cycle and bleeding", isOn: $showCycle)
            Toggle("Medicines and supplements", isOn: $showMedicines)
            Toggle("Your questions", isOn: $showQuestions)
            NavigationLink {
                QuestionsView().analyticsScreen(.questions)
            } label: {
                HStack {
                    Text("Edit questions (\(model.repository.questions().count))")
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                }
                .padding(.vertical, 8)
            }
        }
        .tint(Theme.accent)

        comparisonCard

        NavigationLink {
            ScrollView([.vertical, .horizontal]) {
                let data = makeData()
                VStack(spacing: 12) {
                    ReportPage(data: data)
                    if let comparison = data.comparison {
                        ComparisonPage(profile: data.profile, comparison: comparison)
                    }
                }
                .padding(12)
            }
            .analyticsScreen(.reportPreview)
            .onAppear { UsageAnalytics.shared.log(.reportPreviewed) }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Text("Show on screen")
        }
        .buttonStyle(OutlineButtonStyle())
        .accessibilityIdentifier("report.showOnScreen")

        Button(model.isPro ? "Save PDF" : "Save PDF to print or send") {
            if model.isPro {
                pdfURL = try? ReportPDF.render(makeData())
                UsageAnalytics.shared.log(.pdfSaved, .range(effectiveRange))
            } else {
                lockedTapped(.pdfReport)
            }
        }
        .buttonStyle(PrimaryButtonStyle())

        if let pdfURL {
            ShareLink(item: pdfURL) {
                Label("Share or print PDF", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(OutlineButtonStyle())
        }

        Text("Showing the report on screen is always free.")
            .font(.footnote).foregroundStyle(Theme.muted)
        Disclaimer()
    }

    private var effectiveRange: HistoryRange { HistoryRange.allowed(range.weeks, isPro: model.isPro) }

    private func lockedTapped(_ feature: ProFeature) {
        UsageAnalytics.shared.log(.proFeatureTapped, .feature(feature))
        paywall = feature
    }

    private var splitDay: DayKey {
        split.map { DayKey($0) } ?? PeriodComparison.defaultSplit(visits: model.repository.visits(), today: .today)
    }

    /// "Since your last visit" (Pro): page 2 of the report.
    @ViewBuilder
    private var comparisonCard: some View {
        Card {
            HStack {
                Text("Since your last visit").font(.headline)
                Spacer()
                if !model.isPro { ProBadge() }
            }
            Text("Adds a page with your average ratings before and after a date, such as your last appointment.")
                .font(.subheadline).foregroundStyle(Theme.muted)
            if model.isPro {
                Toggle("Add the comparison page", isOn: $includeComparison)
                    .onChange(of: includeComparison) { _, on in UsageAnalytics.shared.log(.comparisonToggled, .enabled(on)) }
                if includeComparison {
                    DatePicker("Compare before and after", selection: Binding(
                        get: { split ?? splitDay.referenceDate },
                        set: { split = $0 }
                    ), in: ...Date(), displayedComponents: .date)
                    if let comparison = comparison(), !comparison.isReady {
                        Text("Each side needs at least \(PeriodComparison.minimumCheckInsPerSide) check-ins. Pick an earlier date or keep logging.")
                            .font(.footnote).foregroundStyle(Theme.muted)
                    }
                }
            } else {
                Button("Add the comparison page") { lockedTapped(.sinceLastVisit) }
                    .buttonStyle(OutlineButtonStyle())
            }
        }
        .tint(Theme.accent)
    }

    private func comparison() -> PeriodComparison? {
        let profile = model.profile ?? Profile(region: .unitedKingdom, age: nil, trackedSymptomIDs: [])
        let today = DayKey.today
        return PeriodComparison.build(
            split: min(splitDay, today), today: today, symptomIDs: profile.trackedSymptomIDs,
            checkIns: model.repository.allCheckIns(from: splitDay.adding(days: -PeriodComparison.maximumDays), to: today),
            episodes: model.repository.episodes(), questionnaires: model.repository.questionnaires())
    }

    private func makeData() -> ReportData {
        let today = DayKey.today
        let from = effectiveRange.start(endingOn: today)
        let profile = model.profile ?? Profile(region: .unitedKingdom, age: nil, trackedSymptomIDs: [])
        let checkIns = model.repository.allCheckIns(from: from, to: today)
        let summary = ReportSummary.build(
            from: from, to: today,
            trackedSymptomIDs: profile.trackedSymptomIDs,
            checkIns: model.repository.allCheckIns(from: from.adding(days: -28), to: today),
            episodes: model.repository.episodes(),
            questionnaires: model.repository.questionnaires()
        )
        return ReportData(
            profile: profile,
            summary: summary,
            checkIns: checkIns,
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
            medications: showMedicines ? model.repository.medications().filter { $0.stopped.map { $0 >= from } ?? true } : [],
            questions: showQuestions ? model.repository.questions().filter { !$0.asked } : [],
            showHeatMap: showHeatMap,
            showCycle: showCycle,
            comparison: model.isPro && includeComparison ? comparison().flatMap { $0.isReady ? $0 : nil } : nil
        )
    }

    private func loadReason() {
        guard !loadedReason else { return }
        loadedReason = true
        reason = model.repository.currentVisit()?.reason ?? UserDefaults.standard.string(forKey: "report.reasonDraft") ?? ""
    }

    /// The reason lives on the upcoming visit so it is backed up with everything else.
    private func saveReason() {
        guard loadedReason else { return }
        let text = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        if var visit = model.repository.currentVisit() {
            guard visit.reason != text else { return }
            visit.reason = text
            model.repository.save(visit: visit)
        } else {
            // No appointment booked yet. Keep the draft on this iPhone until one is added.
            UserDefaults.standard.set(text, forKey: "report.reasonDraft")
        }
    }
}

// MARK: Paywall

/// One subscription, Tidemark Pro. Prices and the free trial come from StoreKit (the trial shows only when
/// this Apple Account can still get it). In the design catalog, sample prices stand in for the App Store.
struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var feature: ProFeature? = nil
    @State private var selectedID: String?
    @State private var busy = false

    struct Plan: Identifiable {
        let id: String
        let plan: SubscriptionPlan
        let price: String
        let trialDays: Int?
        let product: Product?
    }

    private var plans: [Plan] {
        let store = model.subscription
        let real = store.products.compactMap { product -> Plan? in
            guard let plan = SubscriptionPlan(productID: product.id) else { return nil }
            return Plan(id: product.id, plan: plan, price: product.displayPrice, trialDays: store.trialDays(for: product), product: product)
        }
        if real.isEmpty && DesignFlags.active {
            return [Plan(id: SubscriptionPlan.yearly.productID, plan: .yearly, price: "$39.99", trialDays: 7, product: nil),
                    Plan(id: SubscriptionPlan.monthly.productID, plan: .monthly, price: "$6.99", trialDays: 7, product: nil)]
        }
        return real.sorted { $0.plan == .yearly && $1.plan != .yearly }
    }

    var body: some View {
        let store = model.subscription
        let plans = plans
        let selected = plans.first { $0.id == (selectedID ?? plans.first?.id) }

        NavigationStack {
            Page {
                ScreenHeader(verbatim: "Tidemark Pro")
                Text("Save the one-page PDF to print, email or upload to your \(model.profile?.region.doctorTerm ?? "doctor")'s portal.")
                    .foregroundStyle(Theme.secondary)

                Card(spacing: 8) {
                    let items: [(String, LocalizedStringKey)] = [
                        ("doc.richtext", "PDF report to print, email or upload"),
                        ("arrow.left.arrow.right", "“Since your last visit” comparison page"),
                        ("calendar", "History and reports over 6 and 12 months"),
                        ("tablecells", "Spreadsheet export (CSV)"),
                        ("plus.circle", "Unlimited symptoms, including your own"),
                        ("paintpalette", "Themes and app icons"),
                    ]
                    ForEach(items.indices, id: \.self) { i in
                        Label(items[i].1, systemImage: items[i].0).font(.subheadline)
                    }
                }

                if let error = store.purchaseError {
                    WarningCard(systemImage: "exclamationmark.triangle") {
                        Text("The purchase didn't go through").font(.headline)
                        Text(error).font(.subheadline)
                    }
                }

                if plans.isEmpty {
                    Card {
                        ProgressView()
                        Text("Loading prices from the App Store…").foregroundStyle(Theme.muted)
                    }
                }
                ForEach(plans) { plan in
                    planRow(plan, selected: plan.id == selected?.id, badge: plan.plan == .yearly ? saving(plans) : nil)
                }

                Button(busy ? "Opening the App Store…" : (selected?.trialDays != nil ? "Start free trial" : "Continue")) {
                    guard let product = selected?.product else { return }
                    busy = true
                    Task {
                        await store.purchase(product)
                        busy = false
                        if store.isSubscribed { dismiss() }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(busy || selected?.product == nil)

                Card(spacing: 6) {
                    Text("Always free").font(.headline)
                    let free: [LocalizedStringKey] = ["Daily check-ins and quick logs", "History up to 12 weeks, cycle and patterns", "The report on screen", "iCloud backup and export of all your data"]
                    ForEach(free.indices, id: \.self) { i in
                        Label(free[i], systemImage: "checkmark").font(.subheadline)
                    }
                }

                Button("Restore purchase") { Task { await store.restore(); if store.isSubscribed { dismiss() } } }
                    .frame(maxWidth: .infinity)
                Text("Renews automatically until you cancel in Settings › Apple Account › Subscriptions. Your data stays yours if you cancel.")
                    .font(.caption).foregroundStyle(Theme.muted)
                if plans.contains(where: { $0.trialDays != nil }) {
                    Text("A free trial turns into a paid subscription unless you cancel at least 24 hours before it ends.")
                        .font(.caption).foregroundStyle(Theme.muted)
                }
                HStack(spacing: 16) {
                    Link("Terms of Use", destination: Links.terms)
                    Link("Privacy Policy", destination: Links.privacy)
                }
                .font(.caption)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Not now") { dismiss() } }
            }
        }
        .analyticsScreen(.paywall)
        .onAppear { UsageAnalytics.shared.log(.paywallShown, parameters: feature.map { [.feature($0)] } ?? []) }
    }

    private func planRow(_ plan: Plan, selected: Bool, badge: String?) -> some View {
        let title = plan.plan == .yearly ? String(localized: "Yearly") : String(localized: "Monthly")
        let price = plan.plan == .yearly ? String(localized: "\(plan.price) a year") : String(localized: "\(plan.price) a month")
        let detail: String = if let days = plan.trialDays {
            plan.plan == .yearly ? String(localized: "\(days) days free, then \(plan.price) a year")
                                 : String(localized: "\(days) days free, then \(plan.price) a month")
        } else { price }
        return Button {
            selectedID = plan.id
            UsageAnalytics.shared.log(.planSelected, .plan(plan.plan))
        } label: {
            HStack {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Theme.accent : Theme.chipBorder)
                VStack(alignment: .leading) {
                    Text(verbatim: title).font(.headline).foregroundStyle(Theme.ink)
                    Text(verbatim: detail).font(.subheadline).foregroundStyle(Theme.secondary)
                }
                Spacer()
                if let badge {
                    Text(verbatim: badge).font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .foregroundStyle(Theme.onAccent)
                        .background(Theme.accent, in: Capsule())
                }
            }
            .padding(16)
            .background(selected ? Theme.tint : Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Theme.accentInk : Theme.border, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func saving(_ plans: [Plan]) -> String? {
        guard let yearly = plans.first(where: { $0.plan == .yearly })?.product,
              let monthly = plans.first(where: { $0.plan == .monthly })?.product, monthly.price > 0 else {
            return DesignFlags.active && !plans.isEmpty ? String(localized: "Save \(52)%") : nil
        }
        let full = monthly.price * 12
        let percent = NSDecimalNumber(decimal: (full - yearly.price) / full * 100).intValue
        return percent > 0 ? String(localized: "Save \(percent)%") : nil
    }
}

/// Public pages the App Store requires links to (Guideline 3.1.2). Replace `privacy` with the published policy page.
enum Links {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://baturinigor.github.io/tidemark-legal/privacy.html")!
}
