//
//  AchievementGridView.swift
//  RaccoonCal
//
//  任务 20.6：成就徽章网格（已解锁/未解锁，含进度百分比）
//

import SwiftUI
import UIKit

// MARK: - AchievementGridView

struct AchievementGridView: View {

    let achievements: [Achievement]
    let totalCount: Int
    let unlockedCount: Int

    @State private var selectedAchievement: Achievement?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    init(achievements: [Achievement], totalCount: Int? = nil, unlockedCount: Int? = nil) {
        self.achievements = achievements
        self.totalCount = totalCount ?? achievements.count
        self.unlockedCount = unlockedCount ?? achievements.filter { $0.unlocked }.count
    }

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
            AchievementDetailSheet(achievement: achievement, total: totalCount, unlocked: unlockedCount)
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

                badgeImage(size: 38)
                    .grayscale(achievement.unlocked ? 0 : 1)
                    .opacity(achievement.unlocked ? 1 : 0.5)

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

    @ViewBuilder
    private func badgeImage(size: CGFloat) -> some View {
        if let image = AchievementArtwork.image(for: achievement) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "trophy.fill")
                .font(.system(size: size * 0.65, weight: .semibold))
                .foregroundColor(achievement.unlocked ? AppTheme.primaryDark : AppTheme.textDisabled)
        }
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

                        badgeImage(size: 68)
                            .grayscale(achievement.unlocked ? 0 : 1)
                            .opacity(achievement.unlocked ? 1 : 0.5)
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

    @ViewBuilder
    private func badgeImage(size: CGFloat) -> some View {
        if let image = AchievementArtwork.image(for: achievement) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "trophy.fill")
                .font(.system(size: size * 0.65, weight: .semibold))
                .foregroundColor(achievement.unlocked ? AppTheme.primaryDark : AppTheme.textDisabled)
        }
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

private enum AchievementArtwork {
    private static let keyToAssetName: [String: String] = [
        "first_record": "AchievementFirstRecord",
        "record_10": "AchievementRecord10",
        "record_50": "AchievementRecord50",
        "record_100": "AchievementRecord100",
        "goal_first_day": "AchievementGoalFirstDay",
        "goal_7_days": "AchievementGoal7Days",
        "goal_30_days": "AchievementGoal30Days",
        "streak_3": "AchievementStreak3",
        "streak_7": "AchievementStreak7",
        "streak_30": "AchievementStreak30",
        "streak_100": "AchievementStreak100",
        "level_5": "AchievementLevel5",
        "level_10": "AchievementLevel10",
        "level_20": "AchievementLevel20",
        "level_50": "AchievementLevel50",
        "task_first": "AchievementTaskFirst",
        "task_full_day": "AchievementTaskFullDay",
        "task_full_week": "AchievementTaskFullWeek",
        "pet_first_interact": "AchievementPetFirstInteract",
        "pet_interact_30": "AchievementPetInteract30",
        "league_first_join": "AchievementLeagueFirstJoin",
        "league_promoted": "AchievementLeaguePromoted",
        "weight_first": "AchievementWeightFirst",
        "weight_10_records": "AchievementWeight10Records",
    ]

    static func image(for achievement: Achievement) -> UIImage? {
        for candidate in candidateAssetNames(for: achievement) {
            if let image = UIImage(named: candidate) {
                return image
            }
        }
        return nil
    }

    private static func candidateAssetNames(for achievement: Achievement) -> [String] {
        var names: [String] = []

        if let assetName = keyToAssetName[achievement.key] {
            names.append(assetName)
        }

        names.append(achievement.iconName)

        var uniqueNames: [String] = []
        for name in names where !uniqueNames.contains(name) {
            uniqueNames.append(name)
        }
        return uniqueNames
    }
}

// MARK: - Preview

#Preview {
    let sample: [Achievement] = [
        Achievement(key: "first_record", title: "初次记录", description: "第一次记录饮食", xpReward: 50, iconName: "AchievementFirstRecord", unlocked: true, unlockedAt: "2024-01-15T10:00:00Z"),
        Achievement(key: "streak_7", title: "一周坚持", description: "连续打卡7天", xpReward: 100, iconName: "AchievementStreak7", unlocked: true, unlockedAt: nil),
        Achievement(key: "goal_first_day", title: "初次达标", description: "达成每日卡路里目标", xpReward: 30, iconName: "AchievementGoalFirstDay", unlocked: false, unlockedAt: nil),
        Achievement(key: "streak_30", title: "月度坚持", description: "连续打卡30天", xpReward: 200, iconName: "AchievementStreak30", unlocked: false, unlockedAt: nil),
        Achievement(key: "level_5", title: "初级探索者", description: "达到 5 级", xpReward: 80, iconName: "AchievementLevel5", unlocked: false, unlockedAt: nil),
        Achievement(key: "league_promoted", title: "联盟晋升", description: "联盟排名提升", xpReward: 500, iconName: "AchievementLeaguePromoted", unlocked: false, unlockedAt: nil),
    ]
    ScrollView {
        AchievementGridView(achievements: sample)
            .padding()
    }
    .background(AppTheme.gradientBackground)
}
