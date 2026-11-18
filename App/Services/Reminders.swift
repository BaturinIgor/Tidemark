import Foundation
import TidemarkCore
import UserNotifications

/// Local notifications only: the daily check-in, the Sunday summary and the day before the visit.
enum Reminders {
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func scheduleDaily(hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "30-second check-in"
        content.body = "How was today? Your report updates as you go."
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "daily", content: content, trigger: trigger))
    }

    /// One reminder at 6 PM the day before the next appointment. Saving a visit replaces it.
    static func scheduleVisitEve(for day: DayKey?) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["visit"])
        guard let day else { return }
        let eve = day.adding(days: -1)
        var when = DateComponents(year: eve.year, month: eve.month, day: eve.day, hour: 18)
        when.calendar = Calendar.current
        guard let fire = when.date, fire > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Appointment tomorrow"
        content.body = "Your report is ready. Open it to check your questions."
        try? await center.add(UNNotificationRequest(identifier: "visit", content: content,
                                                    trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false)))
    }

    static func cancelDaily() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily"])
    }

    static func scheduleWeeklySummary() async {
        let content = UNMutableNotificationContent()
        content.title = "Your week"
        content.body = "See how this week compared with last week."
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 18, weekday: 1), repeats: true)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "weekly", content: content, trigger: trigger))
    }
}
