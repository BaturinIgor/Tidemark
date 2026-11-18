import CoreData
import Foundation
import TidemarkCore

/// Writes one hot flush or night sweat. Used by the app, the widget and the Lock Screen control.
enum EpisodeLogger {
    static func log(_ kind: Episode.Kind, intensity: Severity = .moderate, at time: Date = Date(), source: Episode.Source, in context: NSManagedObjectContext) throws {
        try context.performAndWait {
            let row = CDEpisode(context: context)
            row.id = UUID()
            row.kind = kind.rawValue
            row.at = time
            row.intensity = Int16(intensity.rawValue)
            row.source = source.rawValue
            row.updatedAt = Date()
            try context.save()
        }
    }

    static func countToday(in context: NSManagedObjectContext, kind: Episode.Kind = .hotFlush) -> Int {
        let request = CDEpisode.fetchRequest()
        let start = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "kind == %@ AND at >= %@ AND deletedAt == nil", kind.rawValue, start as NSDate)
        return (try? context.performAndWait { try context.count(for: request) }) ?? 0
    }
}
