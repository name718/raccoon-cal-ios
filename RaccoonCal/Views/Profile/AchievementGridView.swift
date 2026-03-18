//
//  AchievementGridView.swift
//  RaccoonCal
//
//  任务 20.6：成就徽章网格（已解锁/未解锁，含进度百分比）
//

import SwiftUI

// MARK: - AchievementGridView

struct AchievementGridView: View {

    let achievements: [Achievement]

    @State private var selectedAchievement: Achievement?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(achievements) { achievement in
                AchievementBadgeCell(achievement: achievement)
                    .onTapGesture { selectedAchievement = achievement }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement, total: achievements.count, unlocked: achievements.filter { $0.unlocked }.count)
        }
    }
}

// MARK: - AchievementBadgeCell

private struct AchievementBadgeCell: View {

    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
            // Badge circle
            ZStack {
                Circle()
                    .fill(achievement.unlocked
                          ? AppTheme.primary.opacity(0.15)
                          : AppTheme.backgroundSecondary)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                achievement.unlocked ? AppTheme.secondary : Color.clear,
                                lineWidth: 2
                            )
                    )

                // Icon emoji or system icon
                Text(emojiForIcon(achievement.iconName))
                    .font(.system(size: 26))
                    .grayscale(achievement.unlocked ? 0 : 1)
                    .opacity(achievement.unlocked ? 1 : 0.4)

                // Lock overlay for locked achievements
                if !achievement.unlocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(3)
                                .background(Circle().fill(AppTheme.textDisabled))
                        }
                    }
                    .frame(width: 56, height: 56)
                }

                // Checkmark overlay for unlocked achievements
                if achievement.unlocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.secondary)
                                .background(Circle().fill(Color.white).frame(width: 12, height: 12))
                        }
                    }
                    .frame(width: 56, height: 56)
                }
            }

            // Title
            Text(achievement.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(achievement.unlocked ? AppTheme.textPrimary : AppTheme.textDisabled)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // Progress / unlocked label
            if achievement.unlocked {
                Text("已解锁")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AppTheme.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AppTheme.secondary.opacity(0.12)))
            } else {
                Text("未解锁")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textDisabled)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.unlocked
                      ? AppTheme.primary.opacity(0.06)
                      : AppTheme.backgroundSecondary.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    achievement.unlocked ? AppTheme.primary.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    /// Map iconName string to an emoji. Falls back to a trophy emoji.
    private func emojiForIcon(_ iconName: String) -> String {
        let map: [String: String] = [
            "trophy":        "🏆",
            "star":          "⭐",
            "fire":          "🔥",
            "streak":        "🔥",
            "food":          "🍱",
            "camera":        "📷",
            "heart":         "❤️",
            "muscle":        "💪",
            "run":           "🏃",
            "salad":         "🥗",
            "apple":         "🍎",
            "water":         "💧",
            "moon":          "🌙",
            "sun":           "☀️",
            "calendar":      "📅",
            "medal":         "🥇",
            "crown":         "👑",
            "lightning":     "⚡",
            "shield":        "🛡️",
            "raccoon":       "🦝",
            "first_record":  "🍱",
            "week_streak":   "🔥",
            "month_streak":  "🏅",
            "century_streak":"🏆",
            "calorie_goal":  "🎯",
            "protein_goal":  "💪",
            "explorer":      "🗺️",
            "social":        "👥",
            "night_owl":     "🦉",
            "early_bird":    "🐦",
        ]
        // Try exact match first, then prefix match
        if let emoji = map[iconName] { return emoji }
        for (key, emoji) in map {
            if iconName.lowercased().contains(key) { return emoji }
        }
        return "🏆"
    }
}

// MARK: - AchievementDetailSheet

private struct AchievementDetailSheet: View {

    let achievement: Achievement
    let total: Int
    let unlocked: Int

    @Environment(\.dismiss) private var dismiss

    /// Overall progress percentage across all achievements
    private var overallProgress: Double {
        guard total > 0 else { return 0 }
        return Double(unlocked) / Double(total)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Badge hero
                    ZStack {
                        Circle()
                            .fill(achievement.unlocked
                                  ? AppTheme.primary.opacity(0.15)
                                  : AppTheme.backgroundSecondary)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        achievement.unlocked ? AppTheme.secondary : AppTheme.textDisabled.opacity(0.3),
                                        lineWidth: 3
                                    )
                            )

                        Text(emojiForIcon(achievement.iconName))
                            .font(.system(size: 48))
                            .grayscale(achievement.unlocked ? 0 : 1)
                            .opacity(achievement.unlocked ? 1 : 0.4)
                    }
                    .padding(.top, 8)

                    // Status badge
                    HStack(spacing: 6) {
                        Image(systemName: achievement.unlocked ? "checkmark.circle.fill" : "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(achievement.unlocked ? AppTheme.secondary : AppTheme.textDisabled)
                        Text(achievement.unlocked ? "已解锁" : "未解锁")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(achievement.unlocked ? AppTheme.secondary : AppTheme.textDisabled)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(
                        achievement.unlocked
                            ? AppTheme.secondary.opacity(0.12)
                            : AppTheme.backgroundSecondary
                    ))

                    // Title & description
                    VStack(spacing: 8) {
                        Text(achievement.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(achievement.description)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    // XP reward
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.primary)
                        Text("+\(achievement.xpReward) XP")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppTheme.primary.opacity(0.1)))

                    // Unlock date (if unlocked)
                    if achievement.unlocked, let dateStr = achievement.unlockedAt {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                            Text("解锁于 \(formattedDate(dateStr))")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    Divider().padding(.horizontal, 16)

                    // Overall progress section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("总体成就进度")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Text("\(unlocked)/\(total)  (\(Int(overallProgress * 100))%)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppTheme.primaryLight.opacity(0.35))
                                    .frame(height: 10)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(
                                        colors: [AppTheme.primaryLight, AppTheme.primary],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: geo.size.width * overallProgress, height: 10)
                                    .animation(.easeInOut(duration: 0.5), value: overallProgress)
                            }
                        }
                        .frame(height: 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("成就详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func emojiForIcon(_ iconName: String) -> String {
        let map: [String: String] = [
            "trophy":        "🏆",
            "star":          "⭐",
            "fire":          "🔥",
            "streak":        "🔥",
            "food":          "🍱",
            "camera":        "📷",
            "heart":         "❤️",
            "muscle":        "💪",
            "run":           "🏃",
            "salad":         "🥗",
            "apple":         "🍎",
            "water":         "💧",
            "moon":          "🌙",
            "sun":           "☀️",
            "calendar":      "📅",
            "medal":         "🥇",
            "crown":         "👑",
            "lightning":     "⚡",
            "shield":        "🛡️",
            "raccoon":       "🦝",
            "first_record":  "🍱",
            "week_streak":   "🔥",
            "month_streak":  "🏅",
            "century_streak":"🏆",
            "calorie_goal":  "🎯",
            "protein_goal":  "💪",
            "explorer":      "🗺️",
            "social":        "👥",
            "night_owl":     "🦉",
            "early_bird":    "🐦",
        ]
        if let emoji = map[iconName] { return emoji }
        for (key, emoji) in map {
            if iconName.lowercased().contains(key) { return emoji }
        }
        return "🏆"
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.dateFormat = "yyyy年MM月dd日"
            return display.string(from: date)
        }
        // Fallback: try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.dateFormat = "yyyy年MM月dd日"
            return display.string(from: date)
        }
        return isoString
    }
}

// MARK: - Preview

#Preview {
    let sample: [Achievement] = [
        Achievement(key: "first_record", title: "初次记录", description: "第一次记录饮食", xpReward: 50, iconName: "food", unlocked: true, unlockedAt: "2024-01-15T10:00:00Z"),
        Achievement(key: "week_streak", title: "7天连续", description: "连续打卡7天", xpReward: 100, iconName: "streak", unlocked: true, unlockedAt: nil),
        Achievement(key: "calorie_goal", title: "达成目标", description: "达成每日卡路里目标", xpReward: 30, iconName: "calorie_goal", unlocked: false, unlockedAt: nil),
        Achievement(key: "month_streak", title: "30天连续", description: "连续打卡30天", xpReward: 200, iconName: "month_streak", unlocked: false, unlockedAt: nil),
        Achievement(key: "explorer", title: "探索者", description: "识别10种不同食物", xpReward: 80, iconName: "explorer", unlocked: false, unlockedAt: nil),
        Achievement(key: "crown", title: "联盟冠军", description: "联盟排名第一", xpReward: 500, iconName: "crown", unlocked: false, unlockedAt: nil),
    ]
    ScrollView {
        AchievementGridView(achievements: sample)
            .padding()
    }
    .background(AppTheme.gradientBackground)
}
