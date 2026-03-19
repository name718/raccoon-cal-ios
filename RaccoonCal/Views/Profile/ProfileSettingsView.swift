//
//  ProfileSettingsView.swift
//  RaccoonCal
//

import SwiftUI

struct ProfileSettingsView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            AppTheme.gradientBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    preferencesCard
                    accountCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .appDialog(
            isPresented: $showLogoutAlert,
            title: "确认退出",
            message: "退出后需要重新登录才能继续使用。",
            tone: .warning,
            primaryAction: AppDialogAction("退出", role: .destructive) {
                userManager.logout()
            },
            secondaryAction: AppDialogAction("取消", role: .cancel)
        )
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image("RaccoonThinking")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("设置中心")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("通知、提醒和账号操作都收在这里，主页会更清爽。")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .settingsCardBackground()
    }

    private var preferencesCard: some View {
        VStack(spacing: 0) {
            sectionTitle("偏好设置")

            NavigationLink(destination: NotificationSettingsView()) {
                settingsRowContent(
                    icon: "bell.badge.fill",
                    color: AppTheme.primary,
                    title: "通知设置",
                    subtitle: "打卡提醒、任务刷新、联盟结算提醒"
                )
            }
            .buttonStyle(.plain)
        }
        .settingsCardBackground()
    }

    private var accountCard: some View {
        VStack(spacing: 0) {
            sectionTitle("账号")

            Button(action: { showLogoutAlert = true }) {
                settingsRowContent(
                    icon: "rectangle.portrait.and.arrow.right",
                    color: AppTheme.error,
                    title: "退出登录",
                    subtitle: "退出当前账号"
                )
            }
            .buttonStyle(.plain)
        }
        .settingsCardBackground()
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private func settingsRowContent(
        icon: String,
        color: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textDisabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private extension View {
    func settingsCardBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }
}

#Preview {
    ProfileSettingsView()
}
