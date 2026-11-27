import Foundation

/// How people reach us. The address lives here and nowhere else.
/// Letters we open carry only the app version or an error code, never anything the user logged.
public enum Feedback {
    public static let address = "dawnwell.app+tidemark@gmail.com"

    /// A `mailto:` link to `address` with a prefilled subject.
    public static func mailURL(subject: String) -> URL {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        return URL(string: "mailto:\(address)?subject=\(encoded)")!
    }

    /// Subject for a general question from Settings.
    public static func generalSubject(appVersion: String?) -> String {
        guard let version = appVersion?.trimmingCharacters(in: .whitespaces), !version.isEmpty else {
            return "Tidemark feedback"
        }
        return "Tidemark \(version) feedback"
    }

    /// Subject for the screen shown when the data store can't be opened. The code is a Core Data error number.
    public static func storeErrorSubject(code: String) -> String {
        let code = code.trimmingCharacters(in: .whitespaces)
        return code.isEmpty ? "Tidemark data error" : "Tidemark data error \(code)"
    }
}
