import SwiftUI
import TidemarkCore

struct ReportData {
    let profile: Profile
    let summary: ReportSummary
    let checkIns: [CheckIn]
    let reason: String
    let medications: [Medication]
    let questions: [DoctorQuestion]
    let showHeatMap: Bool
    let showCycle: Bool
}

/// The one-page visit report. The same view renders on screen and into the PDF, always in light colors.
/// It shows the user's own numbers only: no scores are interpreted and nothing is suggested.
struct ReportPage: View {
    let data: ReportData

    private var region: Region { data.profile.region }
    private var summary: ReportSummary { data.summary }

    var body: some View {
        let size = region.paper.size
        VStack(alignment: .leading, spacing: 10) {
            header
            if !data.reason.isEmpty {
                block("Reason for visit") { Text(data.reason).font(.system(size: 10)) }
            }
            symptomsTable
            HStack(alignment: .top, spacing: 16) {
                questionnaire
                dailyLife
            }
            if data.showHeatMap {
                block("Day by day") {
                    HeatMap(checkIns: data.checkIns, symptomIDs: Array(summary.symptoms.prefix(5).map(\.symptomID)), from: summary.from, to: summary.to)
                }
            }
            HStack(alignment: .top, spacing: 16) {
                if data.showCycle { cycle }
                if !data.medications.isEmpty { medicines }
            }
            if !data.questions.isEmpty {
                block("Questions I want to ask") {
                    ForEach(Array(data.questions.prefix(5).enumerated()), id: \.offset) { item in
                        Text("\(item.offset + 1). \(item.element.text)").font(.system(size: 10))
                    }
                }
            }
            Spacer(minLength: 0)
            footer
        }
        .padding(36)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .foregroundStyle(Color.black)
        .background(Color.white)
        .environment(\.colorScheme, .light)
        .dynamicTypeSize(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Symptom summary for my \(region.doctorTerm)").font(.system(size: 18, weight: .bold))
            Text([
                data.profile.age.map { String(localized: "Age \($0)") },
                String(localized: "\(summary.from.medium) to \(summary.to.medium)"),
                String(localized: "\(summary.daysLogged) of \(summary.daysInRange) days logged"),
            ].compactMap { $0 }.joined(separator: " · "))
            .font(.system(size: 10))
            Text("Recorded by me in the Tidemark app.").font(.system(size: 9)).foregroundStyle(Color.gray)
            Divider()
        }
    }

    private var symptomsTable: some View {
        block("Main symptoms") {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 3) {
                GridRow {
                    Text("Symptom").bold()
                    Text("Days present").bold()
                    Text("Average (0–3)").bold()
                    Text("Last 4 weeks vs 4 before").bold()
                }
                .font(.system(size: 9))
                ForEach(summary.symptoms.prefix(8), id: \.symptomID) { row in
                    GridRow {
                        Text(Symptom.label(for: row.symptomID))
                        Text("\(row.days) of \(summary.daysLogged)")
                        Text(row.average, format: .number.precision(.fractionLength(1)))
                        Text(trendText(row.trend))
                    }
                    .font(.system(size: 10))
                }
            }
            Text("0 none, 1 mild, 2 moderate, 3 severe.").font(.system(size: 8)).foregroundStyle(Color.gray)
        }
    }

    @ViewBuilder
    private var questionnaire: some View {
        block(LocalizedStringKey(Questionnaire.scaleName)) {
            if let last = summary.questionnaires.last, let total = last.total {
                Text("\(total) of \(Questionnaire.maxScore) on \(last.day.medium)").font(.system(size: 11, weight: .semibold))
                ForEach([(QuestionnaireItem.Domain.somatic, String(localized: "Physical")), (.psychological, String(localized: "Mood and mind")), (.urogenital, String(localized: "Intimate and urinary"))], id: \.0) { pair in
                    if let sub = last.subscore(pair.0) {
                        Text("\(pair.1): \(sub.score) of \(sub.max)").font(.system(size: 10))
                    }
                }
                if summary.questionnaires.count > 1 {
                    Text("Earlier: \(summary.questionnaires.dropLast().suffix(3).map { String(localized: "\($0.total ?? 0) on \($0.day.short)") }.joined(separator: ", "))")
                        .font(.system(size: 9))
                }
            } else {
                Text("Not answered in this period.").font(.system(size: 10))
            }
        }
    }

    private var dailyLife: some View {
        block("Daily life") {
            Text("Days symptoms affected me quite a bit or a lot: \(summary.hardImpactDays)").font(.system(size: 10))
            Text("Hot flushes and night sweats logged: \(summary.episodes)").font(.system(size: 10))
        }
    }

    private var cycle: some View {
        block("Cycle and bleeding") {
            let c = summary.cycle
            if let shortest = c.shortestCycle, let longest = c.longestCycle {
                Text(shortest == longest ? "Cycle length \(shortest) days" : "Cycle length \(shortest) to \(longest) days")
            } else {
                Text("Not enough periods logged to show cycle length.")
            }
            if let start = c.lastPeriodStart { Text("Last period started \(start.medium)") }
            Text("Spotting days: \(c.spottingDays) · Heavy bleeding days: \(summary.heavyBleedingDays)")
        }
        .font(.system(size: 10))
    }

    private var medicines: some View {
        block("Medicines and supplements") {
            ForEach(data.medications.prefix(6)) { m in
                Text(verbatim: m.stopped.map { String(localized: "\(m.name), \(m.howTaken), \(m.started.medium) to \($0.medium)") } ?? String(localized: "\(m.name), \(m.howTaken), since \(m.started.medium)"))
                    .font(.system(size: 10))
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            Divider()
            Text("Self-reported symptom record. It is not a diagnosis and does not suggest any treatment.")
            if region == .unitedKingdom {
                Text("UK guidance on menopause: NICE guideline NG23.")
            }
            Text("Made with Tidemark on \(DayKey.today.medium).")
        }
        .font(.system(size: 8))
        .foregroundStyle(Color.gray)
    }

    private func trendText(_ trend: Trend?) -> String {
        switch trend {
        case .higherThanUsual: String(localized: "↑ higher")
        case .lowerThanUsual: String(localized: "↓ lower")
        case .aboutTheSame: String(localized: "→ about the same")
        case nil: String(localized: "not enough days")
        }
    }

    private func block<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 11, weight: .bold)).foregroundStyle(Color(red: 0.055, green: 0.43, blue: 0.42))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum ReportPDF {
    @MainActor
    static func render(_ data: ReportData) throws -> URL {
        let size = data.profile.region.paper.size
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Tidemark report \(data.summary.to.description).pdf")
        let renderer = ImageRenderer(content: ReportPage(data: data))
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdf = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        renderer.render { _, draw in
            pdf.beginPDFPage(nil)
            draw(pdf)
            pdf.endPDFPage()
        }
        pdf.closePDF()
        return url
    }
}
