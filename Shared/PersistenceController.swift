import CoreData
import Foundation
import os

/// Owns the Core Data stack. The app mirrors it to the user's private CloudKit database (D2);
/// the widget opens the same file without CloudKit and the app picks its writes up from persistent history.
final class PersistenceController: @unchecked Sendable {
    static let appGroup = "group.app.tidemark"
    static let cloudContainer = "iCloud.app.tidemark"

    enum Mode { case app, widget, inMemory }

    let container: NSPersistentContainer
    /// Set when the store could not be opened. The app then shows an error screen and writes nothing,
    /// so nothing typed in is silently dropped and onboarding never starts over an existing store.
    private(set) var loadError: String?
    private let log = Logger(subsystem: "app.tidemark", category: "persistence")

    static var storeURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Tidemark.sqlite")
    }

    nonisolated(unsafe) static let model: NSManagedObjectModel = {
        let bundle = Bundle(for: PersistenceController.self)
        guard let url = bundle.url(forResource: "Tidemark", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Tidemark.momd missing from bundle")
        }
        return model
    }()

    init(mode: Mode) {
        switch mode {
        case .app:
            container = NSPersistentCloudKitContainer(name: "Tidemark", managedObjectModel: Self.model)
        case .widget, .inMemory:
            container = NSPersistentContainer(name: "Tidemark", managedObjectModel: Self.model)
        }

        let description = NSPersistentStoreDescription(url: mode == .inMemory ? URL(fileURLWithPath: "/dev/null") : Self.storeURL)
        // History tracking lets the app see what the widget wrote, and lets CloudKit export it.
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        // D6: never let Core Data guess a migration. Lightweight only, and we snapshot first.
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        if mode == .app {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.cloudContainer)
        }
        container.persistentStoreDescriptions = [description]

        if mode != .inMemory { MigrationSnapshot.takeIfNeeded(storeURL: Self.storeURL, model: Self.model) }

        var failure: String?
        container.loadPersistentStores { [log] _, error in
            if let error {
                // D6: do not delete or recreate the store. The snapshot stays on disk for recovery.
                log.fault("Store failed to load: \(error.localizedDescription, privacy: .public)")
                failure = (error as NSError).domain + " \((error as NSError).code)"
            }
        }
        loadError = failure
        container.viewContext.automaticallyMergesChangesFromParent = true
        // D8: newest value wins per attribute, not per record.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.transactionAuthor = mode == .widget ? "widget" : "app"
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}

/// D6: copy the store aside before any schema change, so a failed migration never loses data.
enum MigrationSnapshot {
    static func takeIfNeeded(storeURL: URL, model: NSManagedObjectModel) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: storeURL.path),
              let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
                  ofType: NSSQLiteStoreType, at: storeURL, options: nil),
              !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        else { return }

        let stamp = Int(Date().timeIntervalSince1970)
        let folder = storeURL.deletingLastPathComponent().appendingPathComponent("Snapshots/\(stamp)", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: storeURL.path + suffix)
            guard fm.fileExists(atPath: source.path) else { continue }
            try? fm.copyItem(at: source, to: folder.appendingPathComponent(source.lastPathComponent))
        }
    }
}
