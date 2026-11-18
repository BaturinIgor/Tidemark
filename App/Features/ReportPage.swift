import SwiftUI
import TidemarkCore

struct ReportData {
    let profile: Profile
    let from: DayKey
    let to: DayKey
    let checkIns: [CheckIn]
    let episodes: [Episode]
    let questionnaires: [Questionnaire]
    let medications: [Medication]
}

/// The one-page visit report. The same view renders on screen and into the PDF.
struct ReportPage: View {
    let data: ReportData

    var body: some View {
        let ids = data.profile.trackedSymptomIDs
        let cycle = CycleStats.summary(of: Dictionary(data.checkIns.map { ($0.day, $0.bleeding) }, uniquingKeysWith: { _, b in b }))
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptom summary for your \(data.profile.region.doctorTerm)").font(.title2.bold())
            Text("\(data.from.description) to \(data.to.description) · \(data.checkIns.count) daily check-ins · age \(data.profile.age.map(String.init) ?? "–")")
                .font(.subheadline)

            Text("Main symptoms").font(.headline)
            ForEach(ids, id: \.self) { id in
                let values = data.checkIns.compactMap { $0.ratings[id] }
                let heavyDays = values.filter { $0 >= .moderate }.count
                Text("\(Symptom.catalog.first { $0.id == id }?.label ?? id): moderate or severe on \(heavyDays) of \(values.count) days")
            }
            if !data.episodes.isEmpty {
                Text("Hot flushes and night sweats logged: \(data.episodes.count)")
            }

            if let last = data.questionnaires.last, let total = last.total {
                Text("Menopause Rating Scale: \(total) of \(Questionnaire.maxScore) on \(last.day.description)").font(.headline)
            }

            Text("Cycle").font(.headline)
            if cycle.cycleLengths.isEmpty {
                Text("Not enough periods logged to show cycle length.")
            } else {
                Text("Cycle length \(cycle.shortestCycle ?? 0)–\(cycle.longestCycle ?? 0) days, \(cycle.spottingDays) spotting days")
            }

            Text("Medicines and supplements").font(.headline)
            ForEach(data.medications) { m in
                Text("\(m.name): \(m.howTaken), since \(m.started.description)\(m.stopped.map { ", stopped \($0.description)" } ?? "")")
            }

            Spacer(minLength: 0)
            Text("Recorded by the patient in the Tidemark app. Not a diagnosis.").font(.caption)
        }
        .padding(36)
        .foregroundStyle(.black)
        .background(.white)
    }
}

enum ReportPDF {
    @MainActor
    static func render(_ data: ReportData) throws -> URL {
        let size = data.profile.region.paper.size
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Tidemark report \(data.to.description).pdf")
        let renderer = ImageRenderer(content: ReportPage(data: data).frame(width: size.width, height: size.height))
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
