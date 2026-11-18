import SwiftUI
import TidemarkCore

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            if model.needsOnboarding && model.isRestoring {
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
                TabView {
                    NavigationStack { TodayView() }
                        .tabItem { Label("Today", systemImage: "checkmark.circle") }
                    NavigationStack { HistoryView() }
                        .tabItem { Label("History", systemImage: "chart.bar") }
                    NavigationStack { ReportView() }
                        .tabItem { Label("Report", systemImage: "doc.text") }
                    NavigationStack { SettingsView() }
                        .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                }
            }
            if model.lock.isEnabled && (model.lock.isLocked || model.lock.isObscured) {
                LockView()
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
