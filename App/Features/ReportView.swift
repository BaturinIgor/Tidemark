import SwiftUI
import TidemarkCore

struct ReportView: View {
    @Environment(AppModel.self) private var model
    @State private var weeks = 8
    @State private var pdfURL: URL?
    @State private var showPaywall = false

    var body: some View {
        let checkIns = model.repository.allCheckIns()
        let readiness = ReportReadiness.evaluate(checkIns: checkIns.count, questionnaires: model.repository.questionnaires().count)

        List {
            switch readiness {
            case .locked(let soFar, let needed):
                Section {
                    ProgressView(value: Double(soFar), total: Double(needed))
                    Text("\(needed - soFar) more check-ins and your first report is ready. A week of data shows your doctor a pattern, not one bad day.")
                }
            case .ready(let count, _):
                Section {
                    Picker("Period", selection: $weeks) {
                        Text("4 weeks").tag(4)
                        Text("8 weeks").tag(8)
                        Text("12 weeks").tag(12)
                    }
                    .pickerStyle(.segmented)
                    Text("\(count) check-ins")
                }
                Section {
                    NavigationLink("Show on screen") { ScrollView { ReportPage(data: reportData()) } }
                    Button("Save PDF") {
                        if model.subscription.isSubscribed {
                            pdfURL = try? ReportPDF.render(reportData())
                        } else {
                            showPaywall = true
                        }
                    }
                    if let pdfURL {
                        ShareLink("Share PDF", item: pdfURL)
                    }
                }
            }
        }
        .navigationTitle("Report")
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func reportData() -> ReportData {
        let today = DayKey(Date())
        let from = today.adding(days: -(weeks * 7) + 1)
        return ReportData(
            profile: model.profile ?? Profile(region: .unitedKingdom, age: nil, trackedSymptomIDs: []),
            from: from, to: today,
            checkIns: model.repository.allCheckIns(from: from, to: today),
            episodes: model.repository.episodes().filter { DayKey($0.at) >= from },
            questionnaires: model.repository.questionnaires().filter { $0.day >= from },
            medications: model.repository.medications()
        )
    }
}

struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Daily logging stays free. A subscription adds the PDF report you can print or send.")
                }
                ForEach(model.subscription.products, id: \.id) { product in
                    Button("\(product.displayName), \(product.displayPrice)") {
                        Task { await model.subscription.purchase(product); if model.subscription.isSubscribed { dismiss() } }
                    }
                }
                if let error = model.subscription.purchaseError {
                    Text(error).foregroundStyle(Theme.danger)
                }
                Button("Restore purchase") { Task { await model.subscription.restore() } }
            }
            .navigationTitle("Tidemark report")
        }
    }
}
