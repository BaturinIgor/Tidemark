import LocalAuthentication
import Observation
import SwiftUI

/// Optional Face ID or passcode lock. Off by default; the content is hidden in the app switcher when on.
@MainActor
@Observable
final class AppLock {
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "appLockEnabled") }
    }
    private(set) var isLocked: Bool
    private(set) var isObscured = false

    init() {
        let enabled = UserDefaults.standard.bool(forKey: "appLockEnabled")
        isEnabled = enabled
        isLocked = enabled
    }

    func sceneChanged(to phase: ScenePhase) {
        guard isEnabled else { isObscured = false; return }
        switch phase {
        case .background: isLocked = true
        case .inactive: isObscured = true
        case .active: isObscured = false
        @unknown default: break
        }
    }

    func unlock() async {
        let context = LAContext()
        context.localizedFallbackTitle = String(localized: "Use passcode")
        do {
            let ok = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: String(localized: "Unlock your symptom log"))
            if ok { isLocked = false }
        } catch {
            isLocked = true
        }
    }
}
