import StoreKit
import SwiftUI
import TidemarkCore

/// Report tab: locked until a week of data, then the builder. The PDF needs a subscription; the on-screen view does not.
struct ReportView: View {
    @Environment(AppModel.self) private var model
    @State private var weeks = 8
    @State private var reason = ""
    @State private var loadedReason = false
    @State private var pdfURL: URL?
    @State private var showPaywall = false
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
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear(perform: loadReason)
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
            OptionRow(options: [4, 8, 12], selection: $weeks) { String(localized: "\($0) weeks") }
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
                QuestionsView()
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

        NavigationLink {
            ScrollView([.vertical, .horizontal]) {
                ReportPage(data: makeData())
                    .padding(12)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Text("Show on screen")
        }
        .buttonStyle(OutlineButtonStyle())

        Button(model.subscription.isSubscribed ? "Save PDF" : "Save PDF to print or send") {
            if model.subscription.isSubscribed {
                pdfURL = try? ReportPDF.render(makeData())
            } else {
                showPaywall = true
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

    private func makeData() -> ReportData {
        let today = DayKey.today
        let from = today.adding(days: -(weeks * 7) + 1)
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
            showCycle: showCycle
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

struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: String?
    @State private var busy = false

    var body: some View {
        let store = model.subscription
        let yearly = store.products.first { $0.subscription?.subscriptionPeriod.unit == .year }
        let monthly = store.products.first { $0.subscription?.subscriptionPeriod.unit == .month }

        NavigationStack {
            Page {
                ScreenHeader(title: "Take your report to the appointment")
                Text("Save the one-page PDF to print, email or upload to your \(model.profile?.region.doctorTerm ?? "doctor")'s portal.")
                    .foregroundStyle(Theme.secondary)

                if let error = store.purchaseError {
                    WarningCard(systemImage: "exclamationmark.triangle") {
                        Text("The purchase didn't go through").font(.headline)
                        Text(error).font(.subheadline)
                    }
                }

                if store.products.isEmpty {
                    Card {
                        ProgressView()
                        Text("Loading prices from the App Store…").foregroundStyle(Theme.muted)
                    }
                }
                if let yearly {
                    planRow(yearly, title: String(localized: "Yearly"), detail: String(localized: "\(yearly.displayPrice) a year"), badge: saving(yearly: yearly, monthly: monthly))
                }
                if let monthly {
                    planRow(monthly, title: String(localized: "Monthly"), detail: String(localized: "\(monthly.displayPrice) a month"), badge: nil)
                }

                Button(busy ? "Opening the App Store…" : "Continue") {
                    guard let product = store.products.first(where: { $0.id == (selectedID ?? yearly?.id) }) else { return }
                    busy = true
                    Task {
                        await store.purchase(product)
                        busy = false
                        if store.isSubscribed { dismiss() }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(busy || store.products.isEmpty)

                Card(spacing: 6) {
                    Text("Always free").font(.headline)
                    let free: [LocalizedStringKey] = ["Daily check-ins and quick logs", "History, cycle and patterns", "The report on screen", "iCloud backup and export of all your data"]
                    ForEach(free.indices, id: \.self) { i in
                        Label(free[i], systemImage: "checkmark").font(.subheadline)
                    }
                }

                Button("Restore purchase") { Task { await store.restore(); if store.isSubscribed { dismiss() } } }
                    .frame(maxWidth: .infinity)
                Text("Renews automatically until you cancel in Settings › Apple ID › Subscriptions. Your data stays yours if you cancel.")
                    .font(.caption).foregroundStyle(Theme.muted)
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
    }

    private func planRow(_ product: Product, title: String, detail: String, badge: String?) -> some View {
        let selected = product.id == (selectedID ?? model.subscription.products.first { $0.subscription?.subscriptionPeriod.unit == .year }?.id)
        return Button { selectedID = product.id } label: {
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

    private func saving(yearly: Product, monthly: Product?) -> String? {
        guard let monthly, monthly.price > 0 else { return nil }
        let full = monthly.price * 12
        let percent = NSDecimalNumber(decimal: (full - yearly.price) / full * 100).intValue
        return percent > 0 ? String(localized: "Save \(percent)%") : nil
    }
}

/// Public pages the App Store requires links to (Guideline 3.1.2). Replace `privacy` with the published policy page.
enum Links {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://github.com/BaturinIgor/Tidemark/blob/main/docs/privacy-policy.md")!
}
