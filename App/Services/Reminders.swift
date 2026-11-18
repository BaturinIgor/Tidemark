import Foundation
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

    static func scheduleWeeklySummary() async {
        let content = UNMutableNotificationContent()
        content.title = "Your week"
        content.body = "See how this week compared with last week."
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 18, weekday: 1), repeats: true)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "weekly", content: content, trigger: trigger))
    }
}
