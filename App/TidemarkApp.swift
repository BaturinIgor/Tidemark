import SwiftUI
import TidemarkCore

@main
struct TidemarkApp: App {
    @State private var model = AppModel(persistence: PersistenceController(mode: Self.isRunningTests ? .inMemory : .app))

    /// Unit tests run inside the app; keep them away from the real store and iCloud.
    static var isRunningTests: Bool { ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil }
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(\.managedObjectContext, model.persistence.container.viewContext)
                .tint(Theme.accent)
        }
        .onChange(of: scenePhase) { _, phase in
            model.lock.sceneChanged(to: phase)
            if phase == .active { model.backup.refresh() }
        }
    }
}
