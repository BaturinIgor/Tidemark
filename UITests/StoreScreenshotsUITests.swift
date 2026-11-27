import XCTest

/// Raw App Store screenshots: the six screens behind the captions in docs/app-store.md, in one language.
/// Runs only when STORE_DIR is set (tools/store_screenshots.sh sets it for each language,
/// together with STORE_LANG, STORE_LOCALE and STORE_REGION). Light mode, made-up data, subscribed.
@MainActor
final class StoreScreenshotsUITests: XCTestCase {
    private struct Shot {
        let name: String
        var screen: String? = nil
        var flags: [String] = []
    }

    /// Order and meaning follow "Screenshot captions" in docs/app-store.md.
    private static let shots: [Shot] = [
        Shot(name: "1-report", flags: ["-design-tab", "2", "-design-plus"]),
        Shot(name: "2-check-in", screen: "checkIn"),
        Shot(name: "3-quick-log", screen: "quickLog"),
        Shot(name: "4-history", flags: ["-design-tab", "1"]),
        Shot(name: "5-settings", flags: ["-design-tab", "3"]),
        Shot(name: "6-after-visit", screen: "afterVisit", flags: ["-design-after-visit"]),
    ]

    func testStoreScreenshots() throws {
        let env = ProcessInfo.processInfo.environment
        guard let path = env["STORE_DIR"], !path.isEmpty else {
            throw XCTSkip("STORE_DIR is not set: store screenshots are taken only by tools/store_screenshots.sh")
        }
        let dir = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let lang = env["STORE_LANG"] ?? "en"
        let locale = env["STORE_LOCALE"] ?? "en_GB"
        let region = env["STORE_REGION"] ?? "UK"

        continueAfterFailure = true
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        var missing: [String] = []
        for shot in Self.shots {
            let app = XCUIApplication()
            var args = ["-design", "-AppleLanguages", "(\(lang))", "-AppleLocale", locale,
                        "-design-region", region, "-appLockEnabled", "NO"]
            if let screen = shot.screen { args += ["-design-screen", screen] }
            app.launchArguments = args + shot.flags
            app.launch()

            let ready = shot.screen != nil
                ? app.descendants(matching: .any).matching(identifier: "design.ready").firstMatch.waitForExistence(timeout: 20)
                : app.tabBars.firstMatch.waitForExistence(timeout: 20)
            if !ready { missing.append(shot.name) }
            if shot.name == "1-report" {
                // The report itself, as the doctor sees it, rather than the report settings.
                let button = app.buttons["report.showOnScreen"]
                if button.waitForExistence(timeout: 5) { button.tap() } else { missing.append("1-report preview") }
            }
            sleep(2)
            allowSystemAlerts(springboard)
            try XCUIScreen.main.screenshot().pngRepresentation
                .write(to: dir.appendingPathComponent("\(shot.name).png"))
            app.terminate()
        }
        XCTAssertTrue(missing.isEmpty, "Screens not confirmed in \(lang): \(missing.joined(separator: ", "))")
    }

    /// Answers system permission prompts (notifications) so they don't cover the screen.
    private func allowSystemAlerts(_ springboard: XCUIApplication) {
        for _ in 0..<4 {
            let alert = springboard.alerts.firstMatch
            guard alert.waitForExistence(timeout: 1) else { return }
            alert.buttons.element(boundBy: alert.buttons.count - 1).tap()
            sleep(1)
        }
    }
}
