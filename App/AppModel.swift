import CoreData
import Observation
import SwiftUI
import TidemarkCore

/// App-wide state shared by every tab.
@MainActor
@Observable
final class AppModel {
    let persistence: PersistenceController
    let repository: Repository
    let backup: BackupMonitor
    let lock = AppLock()
    let subscription = SubscriptionStore()
    let health = HealthService()

    var profile: Profile?
    var hasRestorableBackup = false

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.repository = Repository(context: persistence.container.viewContext)
        self.backup = BackupMonitor(container: persistence.container as? NSPersistentCloudKitContainer)
        self.profile = repository.profile()
    }

    var needsOnboarding: Bool { profile == nil }

    func completeOnboarding(_ profile: Profile) {
        repository.save(profile: profile)
        self.profile = profile
    }
}
