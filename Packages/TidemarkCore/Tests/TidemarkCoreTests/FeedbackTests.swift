import Foundation
import Testing
@testable import TidemarkCore

@Suite("Feedback email")
struct FeedbackTests {
    @Test func linkGoesToTheFeedbackAddress() {
        let url = Feedback.mailURL(subject: "Tidemark feedback")
        #expect(url.scheme == "mailto")
        #expect(url.absoluteString.hasPrefix("mailto:dawnwell.app+tidemark@gmail.com?subject="))
    }

    @Test func subjectIsEncodedSoMailAppsReadItBack() {
        let url = Feedback.mailURL(subject: "Tidemark 1.0 feedback & ideas+more")
        #expect(url.absoluteString.hasSuffix("?subject=Tidemark%201.0%20feedback%20%26%20ideas%2Bmore"))
        let subject = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "subject" }?.value
        #expect(subject == "Tidemark 1.0 feedback & ideas+more")
    }

    @Test func subjectsCarryOnlyVersionOrErrorCode() {
        #expect(Feedback.generalSubject(appVersion: "1.0") == "Tidemark 1.0 feedback")
        #expect(Feedback.generalSubject(appVersion: nil) == "Tidemark feedback")
        #expect(Feedback.generalSubject(appVersion: " ") == "Tidemark feedback")
        #expect(Feedback.storeErrorSubject(code: "134110") == "Tidemark data error 134110")
        #expect(Feedback.storeErrorSubject(code: "") == "Tidemark data error")
    }

    @Test func letterHasNoBody() {
        // Nothing the user logged may end up in the letter, so we never prefill a body.
        let url = Feedback.mailURL(subject: "x")
        #expect(!url.absoluteString.contains("body="))
    }
}
