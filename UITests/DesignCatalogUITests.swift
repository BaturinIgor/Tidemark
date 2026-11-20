import XCTest

/// Mockups of every screen, state and popup: design/<version>/screens.
/// Each picture is a separate launch with `-design` (see App/DesignGallery.swift) on made-up data
/// in memory, in light and dark. Runs only when DESIGN_DIR is set (the Design screens workflow).
@MainActor
final class DesignCatalogUITests: XCTestCase {
    private struct Shot {
        let name: String
        var screen: String? = nil
        var alert: String? = nil
        var flags: [String] = []
    }

    private static let shots: [Shot] = [
        // Tabs
        Shot(name: "01-today", flags: ["-design-tab", "0"]),
        Shot(name: "02-today-checked-in", flags: ["-design-tab", "0", "-design-checked-in"]),
        Shot(name: "03-history", flags: ["-design-tab", "1"]),
        Shot(name: "04-report", flags: ["-design-tab", "2"]),
        Shot(name: "05-report-subscribed", flags: ["-design-tab", "2", "-design-plus"]),
        Shot(name: "06-settings", flags: ["-design-tab", "3"]),
        // Empty states (first day after onboarding)
        Shot(name: "07-today-empty", flags: ["-design-tab", "0", "-design-empty"]),
        Shot(name: "08-history-empty", flags: ["-design-tab", "1", "-design-empty"]),
        Shot(name: "09-report-empty", flags: ["-design-tab", "2", "-design-empty"]),
        // Onboarding
        Shot(name: "10-onboarding-welcome", flags: ["-design-onboarding", "-design-step", "0"]),
        Shot(name: "11-onboarding-symptoms", flags: ["-design-onboarding", "-design-step", "1"]),
        Shot(name: "12-onboarding-visit", flags: ["-design-onboarding", "-design-step", "2"]),
        Shot(name: "13-onboarding-restore", flags: ["-design-onboarding", "-design-backup-found"]),
        // Other app states
        Shot(name: "14-today-after-visit", flags: ["-design-tab", "0", "-design-after-visit"]),
        Shot(name: "15-locked", flags: ["-appLockEnabled", "YES"]),
        Shot(name: "16-store-error", flags: ["-design-store-error"]),
        // Sheets
        Shot(name: "17-check-in", screen: "checkIn"),
        Shot(name: "18-check-in-saved", screen: "checkInSaved"),
        Shot(name: "19-questionnaire", screen: "questionnaire"),
        Shot(name: "20-quick-log", screen: "quickLog"),
        Shot(name: "21-after-visit", screen: "afterVisit", flags: ["-design-after-visit"]),
        Shot(name: "22-paywall", screen: "paywall"),
        Shot(name: "23-add-medicine", screen: "addMedication"),
        Shot(name: "24-questions", screen: "questions"),
        // Pushed screens
        Shot(name: "25-your-week", screen: "weekly"),
        Shot(name: "26-cycle", screen: "cycle"),
        Shot(name: "27-patterns", screen: "patterns"),
        Shot(name: "28-medicines", screen: "medications"),
        Shot(name: "29-treatment-check", screen: "treatmentCheck"),
        Shot(name: "30-visit-notes", screen: "visitNotes"),
        Shot(name: "31-my-symptoms", screen: "symptoms"),
        Shot(name: "32-appointment", screen: "appointment"),
        Shot(name: "33-apple-health", screen: "health"),
        Shot(name: "34-recently-deleted", screen: "recentlyDeleted"),
        // Popups
        Shot(name: "35-import-failed", alert: "importFailed", flags: ["-design-tab", "3"]),
        Shot(name: "36-delete-all-confirm", alert: "deleteAll", flags: ["-design-tab", "3"]),
    ]

    private static var outputDir: URL? {
        guard let path = ProcessInfo.processInfo.environment["DESIGN_DIR"], !path.isEmpty else { return nil }
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testLight() throws {
        try run(dark: false)
    }

    func testDark() throws {
        try run(dark: true)
    }

    private func run(dark: Bool) throws {
        guard let dir = Self.outputDir else {
            throw XCTSkip("DESIGN_DIR is not set: design screenshots are taken only by the Design screens workflow")
        }
        continueAfterFailure = true
        var missing: [String] = []
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for shot in Self.shots {
            let app = XCUIApplication()
            var args = ["-design", "-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
            if dark { args.append("-design-dark") }
            if let screen = shot.screen { args += ["-design-screen", screen] }
            if let alert = shot.alert { args += ["-design-alert", alert] }
            if !shot.flags.contains("-appLockEnabled") { args += ["-appLockEnabled", "NO"] }
            app.launchArguments = args + shot.flags
            app.launch()

            let ready: Bool
            if shot.alert != nil {
                ready = app.alerts.firstMatch.waitForExistence(timeout: 10)
                    || app.sheets.firstMatch.waitForExistence(timeout: 2)
                    || app.buttons["Delete everything"].waitForExistence(timeout: 2)
            } else if shot.screen != nil {
                ready = app.descendants(matching: .any).matching(identifier: "design.ready").firstMatch.waitForExistence(timeout: 20)
            } else if shot.flags.contains("-design-tab") {
                ready = app.tabBars.firstMatch.waitForExistence(timeout: 20)
            } else {
                ready = app.staticTexts.firstMatch.waitForExistence(timeout: 20)
            }
            if !ready { missing.append(shot.name) }
            // Let animations finish.
            sleep(2)
            let theme = dark ? "dark" : "light"
            if springboard.alerts.firstMatch.exists {
                // A system permission prompt is a state of the screen too.
                try? XCUIScreen.main.screenshot().pngRepresentation
                    .write(to: dir.appendingPathComponent("\(shot.name)-permission-\(theme).png"))
                allowSystemAlerts(springboard)
                sleep(2)
            }
            try? XCUIScreen.main.screenshot().pngRepresentation
                .write(to: dir.appendingPathComponent("\(shot.name)-\(theme).png"))
            app.terminate()
            allowSystemAlerts(springboard)
        }
        let note = missing.isEmpty ? "all screens shown" : "not confirmed: " + missing.joined(separator: ", ")
        try? note.write(to: dir.appendingPathComponent("report-\(dark ? "dark" : "light").txt"), atomically: true, encoding: .utf8)
        print("==== DESIGN \(dark ? "dark" : "light"): \(note)")
    }

    /// Answers system permission prompts over the app.
    private func allowSystemAlerts(_ springboard: XCUIApplication) {
        for _ in 0..<4 {
            let alert = springboard.alerts.firstMatch
            guard alert.waitForExistence(timeout: 1) else { return }
            let button = ["Allow", "OK"].lazy.map { alert.buttons[$0] }.first { $0.exists }
                ?? alert.buttons.element(boundBy: alert.buttons.count - 1)
            button.tap()
            sleep(1)
        }
    }
}
