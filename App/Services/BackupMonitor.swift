import CloudKit
import CoreData
import Foundation
import Observation
import TidemarkCore

/// Watches CloudKit mirroring and turns it into the D4 banner state.
@MainActor
@Observable
final class BackupMonitor {
    private(set) var health: BackupHealth = .warning(.neverBackedUp)
    private(set) var lastSuccess: Date? {
        didSet { UserDefaults.standard.set(lastSuccess, forKey: "lastBackupSuccess") }
    }
    private var signedIn = true
    private var quotaExceeded = false
    private let container: NSPersistentCloudKitContainer?
    @ObservationIgnored private var observer: NSObjectProtocol?

    init(container: NSPersistentCloudKitContainer?) {
        self.container = container
        self.lastSuccess = UserDefaults.standard.object(forKey: "lastBackupSuccess") as? Date
        guard let container else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification, object: container, queue: .main
        ) { [weak self] note in
            guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event, event.endDate != nil else { return }
            let succeeded = event.succeeded
            let isExport = event.type == .export
            let quota = (event.error as? CKError)?.code == .quotaExceeded
            MainActor.assumeIsolated {
                guard let self else { return }
                if quota { self.quotaExceeded = true }
                if succeeded && isExport {
                    self.quotaExceeded = false
                    self.lastSuccess = Date()
                }
                self.recompute()
            }
        }
        refresh()
    }

    var isEnabled: Bool { container != nil }

    /// CKContainer traps when the process has no iCloud entitlement (unit tests, unsigned builds),
    /// so every CloudKit call is skipped unless the store is actually mirrored.
    func refresh() {
        guard isEnabled else { return }
        Task {
            let status = try? await CKContainer(identifier: PersistenceController.cloudContainer).accountStatus()
            signedIn = status == .available
            recompute()
        }
    }

    private func recompute() {
        health = BackupHealth.evaluate(signedIn: signedIn, quotaExceeded: quotaExceeded, lastSuccess: lastSuccess, now: Date())
    }

    /// D3: before onboarding, look for data already in the user's iCloud.
    func hasExistingBackup() async -> Bool {
        guard isEnabled else { return false }
        guard let status = try? await CKContainer(identifier: PersistenceController.cloudContainer).accountStatus(),
              status == .available else { return false }
        let zone = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone")
        let database = CKContainer(identifier: PersistenceController.cloudContainer).privateCloudDatabase
        return (try? await database.recordZone(for: zone)) != nil
    }
}
