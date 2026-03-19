//
//  NotificationSettingsView.swift
//  RaccoonCal
//
//  任务 20.9：通知设置（打卡提醒 / 任务刷新 / 联盟结算）
//

import SwiftUI
import UserNotifications

// MARK: - UserDefaults Keys

private enum NotifKey {
    static let checkinEnabled    = "notif_checkin_enabled"
    static let checkinHour       = "notif_checkin_hour"
    static let checkinMinute     = "notif_checkin_minute"
    static let taskRefreshEnabled = "notif_taskrefresh_enabled"
    static let taskRefreshHour   = "notif_taskrefresh_hour"
    static let taskRefreshMinute = "notif_taskrefresh_minute"
    static let leagueEnabled     = "notif_league_enabled"
}

// MARK: - NotificationSettingsView

struct NotificationSettingsView: View {
    // MARK: - Notification Manager

    private let notificationManager = NotificationManager.shared

    // MARK: - Persisted State

    @AppStorage(NotifKey.checkinEnabled)     private var checkinEnabled: Bool = false
    @AppStorage(NotifKey.checkinHour)        private var checkinHour: Int = 20
    @AppStorage(NotifKey.checkinMinute)      private var checkinMinute: Int = 0

    @AppStorage(NotifKey.taskRefreshEnabled) private var taskRefreshEnabled: Bool = false
    @AppStorage(NotifKey.taskRefreshHour)    private var taskRefreshHour: Int = 9
    @AppStorage(NotifKey.taskRefreshMinute)  private var taskRefreshMinute: Int = 0

    @AppStorage(NotifKey.leagueEnabled)      private var leagueEnabled: Bool = false

    // MARK: - Local date bindings (derived from stored hour/minute)

    private var checkinTime: Binding<Date> {
        Binding(
            get: { makeDate(hour: checkinHour, minute: checkinMinute) },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                checkinHour   = comps.hour   ?? 20
                checkinMinute = comps.minute ?? 0
                if checkinEnabled {
                    Task { await scheduleCheckin() }
                }
            }
        )
    }

    private var taskRefreshTime: Binding<Date> {
        Binding(
            get: { makeDate(hour: taskRefreshHour, minute: taskRefreshMinute) },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                taskRefreshHour   = comps.hour   ?? 9
                taskRefreshMinute = comps.minute ?? 0
                if taskRefreshEnabled {
                    Task { await scheduleTaskRefresh() }
                }
            }
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.gradientBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerImage
                    checkinCard
                    taskRefreshCard
                    leagueCard
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerImage: some View {
        VStack(spacing: 8) {
            Image("RaccoonNotification")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            Text("让浣熊按时提醒你")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - 打卡提醒 Card

    private var checkinCard: some View {
        notifCard {
            // Toggle row
            notifToggleRow(
                icon: "checkmark.seal.fill",
                iconColor: AppTheme.secondary,
                title: "打卡提醒",
                subtitle: "每天提醒你记录饮食",
                isOn: Binding(
                    get: { checkinEnabled },
                    set: { newVal in
                        checkinEnabled = newVal
                        Task {
                            if newVal {
                                await scheduleCheckin()
                            } else {
                                notificationManager.cancelDailyCheckin()
                            }
                        }
                    }
                )
            )

            if checkinEnabled {
                Divider().padding(.horizontal, 16)
                timePickerRow(label: "提醒时间", selection: checkinTime)
            }
        }
    }

    // MARK: - 任务刷新 Card

    private var taskRefreshCard: some View {
        notifCard {
            notifToggleRow(
                icon: "arrow.clockwise.circle.fill",
                iconColor: AppTheme.info,
                title: "任务刷新提醒",
                subtitle: "每天提醒你查看新任务",
                isOn: Binding(
                    get: { taskRefreshEnabled },
                    set: { newVal in
                        taskRefreshEnabled = newVal
                        Task {
                            if newVal {
                                await scheduleTaskRefresh()
                            } else {
                                cancelTaskRefresh()
                            }
                        }
                    }
                )
            )

            if taskRefreshEnabled {
                Divider().padding(.horizontal, 16)
                timePickerRow(label: "提醒时间", selection: taskRefreshTime)
            }
        }
    }

    // MARK: - 联盟结算 Card

    private var leagueCard: some View {
        notifCard {
            notifToggleRow(
                icon: "person.3.fill",
                iconColor: AppTheme.warning,
                title: "联盟结算提醒",
                subtitle: "每周日提醒联盟排名结算",
                isOn: Binding(
                    get: { leagueEnabled },
                    set: { newVal in
                        leagueEnabled = newVal
                        // League settlement is weekly — no time picker needed.
                        // Scheduling is handled server-side; this toggle is a preference flag.
                    }
                )
            )
        }
    }

    // MARK: - Reusable Card Container

    @ViewBuilder
    private func notifCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    // MARK: - Toggle Row

    private func notifToggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Time Picker Row

    private func timePickerRow(label: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(AppTheme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func makeDate(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour   = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }

    // MARK: - Scheduling

    private func scheduleCheckin() async {
        let granted = await notificationManager.requestPermission()
        guard granted else { return }
        notificationManager.scheduleDailyCheckin(hour: checkinHour, minute: checkinMinute)
    }

    private func scheduleTaskRefresh() async {
        let granted = await notificationManager.requestPermission()
        guard granted else { return }
        notificationManager.scheduleTaskRefresh(hour: taskRefreshHour, minute: taskRefreshMinute)
    }

    private func cancelTaskRefresh() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["com.raccoon-cal.notification.task-refresh"])
    }
}

// MARK: - Preview

#Preview {
    NotificationSettingsView()
}
