import Foundation

/// User-facing words from this package come from its own string catalog (`Resources/Localizable.xcstrings`).
/// Keys are the English text, so a missing translation still shows readable English.
enum L10n {
    static func text(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module)
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: text(key), locale: .current, arguments: args)
    }
}
