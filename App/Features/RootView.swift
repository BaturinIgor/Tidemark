import SwiftUI
import TidemarkCore

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            if model.needsOnboarding {
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
    }
}

struct LockView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill").font(.largeTitle).foregroundStyle(Theme.accent)
            Text("Tidemark is locked").font(.title2.bold())
            Button("Unlock with Face ID") { Task { await model.lock.unlock() } }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .task { if model.lock.isLocked { await model.lock.unlock() } }
    }
}
