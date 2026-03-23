//
//  ProfileSettingsView.swift
//  RaccoonCal
//

import SwiftUI

struct ProfileSettingsView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var showLogoutAlert = false
    
    private var currentUsername: String {
        userManager.currentUser?.username ?? "当前账号"
    }
    
    private var currentAccountLine: String {
        if let email = userManager.currentUser?.email, !email.isEmpty {
            return email
        }
        if let phone = userManager.currentUser?.phone, !phone.isEmpty {
            return phone
        }
        return "账号信息已同步"
    }

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
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.primary.opacity(0.10))
                    .frame(width: 76, height: 76)

                Image("RaccoonThinking")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("设置中心")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("把通知、提醒和账号操作收进一个完整页面，信息更清晰。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentUsername)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(currentAccountLine)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                )
            }

            Spacer(minLength: 0)
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
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.80))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.92), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
        )
    }
}

#Preview {
    ProfileSettingsView()
}
