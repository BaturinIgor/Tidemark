import SwiftUI
import TidemarkCore

/// Colors from the palette board in the mockups. Teal passes 4.5:1 on white and on the app background.
enum Theme {
    static let accent = Color("AccentColor")
    static let ink = Color(red: 0.106, green: 0.122, blue: 0.137)        // #1B1F23
    static let secondary = Color(red: 0.239, green: 0.278, blue: 0.314)  // #3D4750
    static let background = Color(red: 0.965, green: 0.969, blue: 0.961) // #F6F7F5
    static let bleeding = Color(red: 0.761, green: 0.337, blue: 0.184)   // #C2562F
    static let danger = Color(red: 0.639, green: 0.188, blue: 0.102)     // #A3301A

    /// Severity ramp: none, mild, moderate, severe.
    static func fill(_ severity: Severity) -> Color {
        switch severity {
        case .none: Color(.systemBackground)
        case .mild: Color(red: 0.812, green: 0.898, blue: 0.886)     // #CFE5E2
        case .moderate: Color(red: 0.373, green: 0.663, blue: 0.639) // #5FA9A3
        case .severe: Color(red: 0.055, green: 0.431, blue: 0.420)   // #0E6E6B
        }
    }
}
