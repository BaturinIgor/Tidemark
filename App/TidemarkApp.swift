import SwiftUI
import TidemarkCore

@main
struct TidemarkApp: App {
    @State private var model = Self.makeModel()

    /// Unit tests run inside the app; keep them away from the real store and iCloud.
    static var isRunningTests: Bool { ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil }
    @Environment(\.scenePhase) private var scenePhase

    /// Debug design catalog: made-up data in memory, never the real store.
    private static func makeModel() -> AppModel {
        #if DEBUG
        if DesignFlags.active { return DesignData.makeModel() }
        #endif
        return AppModel(persistence: PersistenceController(mode: isRunningTests ? .inMemory : .app))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .designPresenter()
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
