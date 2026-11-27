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

    var profile: Profile? {
        didSet { CustomSymptomNames.shared.update(profile?.customSymptoms ?? []) }
    }
    /// Kept here, not in RootView, so changing the theme (which rebuilds the views) keeps the tab.
    var selectedTab = DesignFlags.initialTab {
        didSet {
            guard selectedTab != oldValue, let tab = [AppTab.today, .history, .report, .settings][safe: selectedTab] else { return }
            UsageAnalytics.shared.log(.tabSelected, .tab(tab))
        }
    }

    /// One subscription unlocks everything in ProFeature.
    var isPro: Bool { subscription.isSubscribed }
    /// D3: the user chose "Restore my data" and we wait for CloudKit to import it.
    var isRestoring = false
    /// Bumped whenever data changes here or arrives from another device, so screens re-read.
    var revision = 0

    @ObservationIgnored private var remoteChanges: NSObjectProtocol?

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.repository = Repository(context: persistence.container.viewContext)
        self.backup = BackupMonitor(container: persistence.container as? NSPersistentCloudKitContainer)
        self.profile = repository.profile()
        CustomSymptomNames.shared.update(profile?.customSymptoms ?? [])
        remoteChanges = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange, object: persistence.container.persistentStoreCoordinator, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.dataChanged() }
        }
    }

    var needsOnboarding: Bool { profile == nil }

    /// The data store could not be opened. Nothing may be written until it can.
    var storeUnavailable: Bool { persistence.loadError != nil }

    func completeOnboarding(_ profile: Profile) {
        repository.save(profile: profile)
        self.profile = profile
        dataChanged()
    }

    func update(profile: Profile) {
        repository.save(profile: profile)
        self.profile = profile
        dataChanged()
    }

    func waitForRestore() {
        isRestoring = true
    }

    /// Call after any write, so views showing derived numbers refresh.
    func dataChanged() {
        if profile == nil, let restored = repository.profile() {
            profile = restored
            isRestoring = false
        } else if let fresh = repository.profile(), fresh != profile {
            // Synced or imported changes (for example custom symptom names) show up right away.
            profile = fresh
        }
        revision += 1
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
