import SwiftUI
import TidemarkCore

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        ZStack {
            if model.storeUnavailable || DesignFlags.has("-design-store-error") {
                StoreErrorView(code: model.persistence.loadError ?? (DesignFlags.active ? "134110" : ""))
                    .analyticsScreen(.storeError)
            } else if model.needsOnboarding && model.isRestoring {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Bringing your data back from iCloud…").font(.headline)
                    Text("This can take a minute on a new iPhone. Keep the app open.")
                        .font(.subheadline).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background.ignoresSafeArea())
            } else if model.needsOnboarding {
                OnboardingView()
            } else {
                TabView(selection: $model.selectedTab) {
                    NavigationStack { TodayView().analyticsScreen(.today) }
                        .tabItem { Label("Today", systemImage: "checkmark.circle") }
                        .tag(0)
                    NavigationStack { HistoryView() }
                        .tabItem { Label("History", systemImage: "chart.bar") }
                        .tag(1)
                    NavigationStack { ReportView() }
                        .tabItem { Label("Report", systemImage: "doc.text") }
                        .tag(2)
                    NavigationStack { SettingsView().analyticsScreen(.settings) }
                        .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                        .tag(3)
                }
            }
            if model.lock.isEnabled && (model.lock.isLocked || model.lock.isObscured) {
                LockView().analyticsScreen(.lock)
            }
        }
        .tint(Theme.accent)
    }
}

struct LockView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "faceid")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
                .frame(width: 84, height: 84)
                .background(Theme.tint, in: RoundedRectangle(cornerRadius: 24))
            Text("Tidemark is locked").font(.title.bold())
            Text("Your log is hidden until you unlock.").foregroundStyle(Theme.secondary)
            if model.lock.isLocked {
                Button("Unlock with Face ID") { Task { await model.lock.unlock() } }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 24)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .task { if model.lock.isLocked { await model.lock.unlock() } }
    }
}

/// Shown when the data store can't be opened. Never offers to reset or start over.
struct StoreErrorView: View {
    let code: String

    var body: some View {
        Page(spacing: 16) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(Theme.danger)
            Text("Tidemark can't open your data right now").font(.title2.bold())
            Text("Nothing has been deleted. Your check-ins are still on this iPhone and in your iCloud backup.")
            Text("Please don't delete the app, because that would remove the copy on this iPhone. Close Tidemark and open it again, restart your iPhone, or update the app from the App Store.")
            Text("If this keeps happening, contact us and quote this code: \(code)")
                .font(.footnote).foregroundStyle(Theme.muted)
            // The address is the link's title, so it stays readable when Mail isn't set up.
            Link(Feedback.address, destination: Feedback.mailURL(subject: Feedback.storeErrorSubject(code: code)))
                .font(.footnote)
                .textSelection(.enabled)
        }
    }
}
