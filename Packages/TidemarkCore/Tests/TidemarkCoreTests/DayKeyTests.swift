import Foundation
import Testing
@testable import TidemarkCore

@Suite("Day keys")
struct DayKeyTests {
    @Test func roundTripsThroughString() {
        let key = DayKey(year: 2026, month: 11, day: 18)
        #expect(key.description == "2026-11-18")
        #expect(DayKey(string: "2026-11-18") == key)
        #expect(DayKey(string: "2026-13-01") == nil)
    }

    @Test func arithmeticCrossesMonthAndYear() {
        #expect(DayKey(year: 2026, month: 12, day: 31).adding(days: 1) == DayKey(year: 2027, month: 1, day: 1))
        #expect(DayKey(year: 2026, month: 9, day: 21).days(until: DayKey(year: 2026, month: 11, day: 18)) == 58)
    }

    @Test func eveningCheckInStaysOnLocalDayWhenTravelling() {
        // 9:13 pm in New York on 18 Nov is already 19 Nov in UTC.
        let date = ISO8601DateFormatter().date(from: "2026-11-19T02:13:00Z")!
        let newYork = TimeZone(identifier: "America/New_York")!
        #expect(DayKey(date, in: newYork) == DayKey(year: 2026, month: 11, day: 18))
    }
}
