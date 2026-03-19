//
//  NotificationManager.swift
//  RaccoonCal
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Notification Identifiers

    private enum NotificationID {
        static let dailyCheckin = "com.raccoon-cal.notification.daily-checkin"
        static let taskRefresh  = "com.raccoon-cal.notification.task-refresh"
        static let streakRisk   = "com.raccoon-cal.notification.streak-risk"
        static let petMissing   = "com.raccoon-cal.notification.pet-missing"
    }

    // MARK: - Init

    private init() {}

    // MARK: - Permission

    /// 请求通知权限，返回用户是否授权
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("[NotificationManager] Permission granted: \(granted)")
            return granted
        } catch {
            print("[NotificationManager] requestPermission error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Daily Check-in Reminder (Property 28, 29, 30)

    /// 调度每日打卡提醒（默认 20:00，重复）。
    /// 注册前先取消旧通知，确保修改时间后旧通知不再触发（Property 28）。
    func scheduleDailyCheckin(hour: Int = 20, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()

        // 先取消旧通知（Property 28）
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.dailyCheckin])

        let content = UNMutableNotificationContent()
        content.title = "每日打卡提醒"
        content.body = "别忘了记录今天的饮食，浣熊在等你哦！"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        // repeats: true 保证每天只触发一次（Property 29）
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.dailyCheckin,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationManager] scheduleDailyCheckin error: \(error.localizedDescription)")
            } else {
                print("[NotificationManager] Daily check-in scheduled at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }

    /// 完成打卡后取消每日打卡提醒（Property 30）
    func cancelDailyCheckin() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [NotificationID.dailyCheckin])
        print("[NotificationManager] Daily check-in notification cancelled")
    }

    // MARK: - Task Refresh Reminder

    /// 调度每日任务刷新提醒（默认 09:00，重复）。
    /// 注册前先取消旧通知（Property 28）。
    func scheduleTaskRefresh(hour: Int = 9, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.taskRefresh])

        let content = UNMutableNotificationContent()
        content.title = "今日任务已刷新"
        content.body = "新的一天，新的挑战！快来完成今日任务吧。"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.taskRefresh,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationManager] scheduleTaskRefresh error: \(error.localizedDescription)")
            } else {
                print("[NotificationManager] Task refresh scheduled at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }

    // MARK: - Streak Risk Warning

    /// 调度当日 19:00 的连续打卡风险提醒（非重复，当天触发一次）。
    func scheduleStreakRisk() {
        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.streakRisk])

        let content = UNMutableNotificationContent()
        content.title = "连续打卡即将中断"
        content.body = "今天还没打卡！快去记录饮食，保住你的连续记录吧。"
        content.sound = .default

        // 当日 19:00，非重复
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = 19
        dateComponents.minute = 0
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.streakRisk,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationManager] scheduleStreakRisk error: \(error.localizedDescription)")
            } else {
                print("[NotificationManager] Streak risk notification scheduled for today at 19:00")
            }
        }
    }

    // MARK: - Pet Missing Notification

    /// 连续 3 天未打卡后触发的宠物思念提醒（非重复，立即触发）。
    func schedulePetMissing() {
        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.petMissing])

        let content = UNMutableNotificationContent()
        content.title = "浣熊好想你"
        content.body = "你已经 3 天没有打卡了，浣熊非常想念你，快回来吧！"
        content.sound = .default

        // 立即触发（timeInterval 需 > 0）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.petMissing,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationManager] schedulePetMissing error: \(error.localizedDescription)")
            } else {
                print("[NotificationManager] Pet missing notification scheduled")
            }
        }
    }
}
