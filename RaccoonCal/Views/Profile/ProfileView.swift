//
//  ProfileView.swift
//  RaccoonCal
//
//  个人资料页容器（任务 20.1）：
//  - ScrollView + NavigationView 布局骨架
//  - 集成 GamificationManager 和 UserManager（singleton）
//  - 为 20.2–20.10 各内容区预留占位 section
//  - onAppear 并发加载：个人资料 / 游戏化状态 / 体重历史
//

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    // MARK: - Dependencies

    @StateObject private var gamificationManager = GamificationManager.shared
    @StateObject private var userManager = UserManager.shared

    // MARK: - State

    @State private var userProfile: UserProfile?
    @State private var weightHistory: [WeightRecord] = []
    @State private var isLoading = false
    @State private var nutritionStats: NutritionStats?
    @State private var isLoadingStats = false
    @State private var errorMessage: String? = nil

    // Sheet / alert flags
    @State private var showEditProfile = false
    @State private var showLeagueSettlement = false
    @State private var showAllAchievements = false

    // MARK: - Computed helpers

    private var nickname: String {
        userProfile?.nickname ?? userManager.currentUser?.username ?? "未设置昵称"
    }

    private var currentLevel: Int? { gamificationManager.gamificationStatus?.level }
    private var totalXp: Int?     { gamificationManager.gamificationStatus?.totalXp }
    private var levelProgress: Double { gamificationManager.gamificationStatus?.levelProgress ?? 0 }
    private var streakDays: Int?  { gamificationManager.gamificationStatus?.streakDays }

    private var unlockedCount: Int { gamificationManager.achievements.filter { $0.unlocked }.count }
    private var totalAchievements: Int { gamificationManager.achievements.count }
    private var sortedAchievements: [Achievement] {
        gamificationManager.achievements.sorted { lhs, rhs in
            if lhs.unlocked != rhs.unlocked {
                return lhs.unlocked && !rhs.unlocked
            }
            return lhs.key < rhs.key
        }
    }
    private var shouldCollapseAchievements: Bool { sortedAchievements.count > 6 }
    private var displayedAchievements: [Achievement] {
        showAllAchievements ? sortedAchievements : Array(sortedAchievements.prefix(6))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.gradientBackground.ignoresSafeArea()

                if isLoading && userProfile == nil {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            userInfoSection          // 20.2
                            healthSummarySection     // 20.4
                            xpLevelSection           // 20.5
                            achievementsSection      // 20.6
                            leagueSection            // 20.7
                            weightHistorySection     // 20.8
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                        .appMainTabScrollableContent()
                    }
                    .refreshable {
                        await loadAllData(showPageError: false)
                        await loadSettlementIfNeeded(showPageError: false)
                    }
                }

                Color.clear
                    .frame(width: 0, height: 0)
                    .appDialog(
                        isPresented: Binding(
                            get: { errorMessage != nil },
                            set: { if !$0 { errorMessage = nil } }
                        ),
                        title: "加载失败",
                        message: errorMessage ?? "",
                        tone: .error,
                        primaryAction: AppDialogAction("确定") { errorMessage = nil }
                    )
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileSettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                    .accessibilityLabel("打开设置")
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let profile = userProfile {
                    ProfileEditView(profile: profile) { updated in
                        userProfile = updated
                    }
                }
            }
            .sheet(isPresented: $showLeagueSettlement) {
                if let settlement = gamificationManager.leagueSettlement {
                    LeagueSettlementSheet(settlement: settlement) {
                        showLeagueSettlement = false
                        UserDefaults.standard.set(true, forKey: "leagueSettlementDismissed_\(settlement.finalRank)_\(settlement.newTier)")
                    }
                }
            }
        }
        .delayedLoadingOverlay(
            isLoading: isLoading || isLoadingStats || gamificationManager.isLoading,
            message: "正在加载个人数据..."
        )
        .task {
            await loadAllData(showPageError: true)
            await loadSettlementIfNeeded(showPageError: false)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            Image("RaccoonGreeting")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)

            ProgressView().scaleEffect(1.1)

            Text("正在整理你的个人数据")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            Text("包括资料、联盟、成就和体重趋势。")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.94), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 8)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 20.2 用户信息区

    private var userInfoSection: some View {
        VStack(spacing: 0) {
            // 顶部：头像 + 昵称 + 编辑按钮
            HStack(spacing: 16) {
                // 头像
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryLight.opacity(0.5))
                        .frame(width: 72, height: 72)
                    Image("RaccoonHappy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(nickname)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        badgeView(icon: "star.fill", text: currentLevel.map { "Lv.\($0)" } ?? "Lv.--", color: AppTheme.primary)
                        badgeView(
                            icon: "flame.fill",
                            text: streakDays.map { "\($0) 天" } ?? "--",
                            color: (streakDays ?? 0) > 0 ? AppTheme.warning : AppTheme.textDisabled
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 20.3 编辑入口
                Button(action: { showEditProfile = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.primary.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if let p = userProfile {
                Divider().padding(.horizontal, 16)

                // 身高 / 体重 / 年龄 三格
                HStack(spacing: 0) {
                    profileStatCell(value: "\(Int(p.height))", unit: "cm", label: "身高")
                    Divider().frame(height: 36)
                    profileStatCell(value: String(format: "%.1f", p.weight), unit: "kg", label: "体重")
                    Divider().frame(height: 36)
                    profileStatCell(value: "\(p.age)", unit: "岁", label: "年龄")
                }
                .padding(.vertical, 10)

                Divider().padding(.horizontal, 16)

                // 目标 / 活动水平 两行
                VStack(spacing: 8) {
                    profileInfoRow(
                        icon: "scope",
                        label: "目标",
                        value: goalDisplayName(p.goal),
                        color: AppTheme.secondary
                    )
                    profileInfoRow(
                        icon: "figure.walk",
                        label: "活动水平",
                        value: activityLevelDisplayName(p.activityLevel),
                        color: AppTheme.info
                    )
                    profileInfoRow(
                        icon: "flame.fill",
                        label: "每日卡路里目标",
                        value: "\(p.dailyCalTarget) kcal",
                        color: AppTheme.warning
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else {
                // 未加载时的引导提示
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundColor(AppTheme.textDisabled)
                    Text("完善个人信息以获得精准卡路里目标")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textDisabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .cardBackground()
    }

    // MARK: - 用户信息辅助视图

    private func profileStatCell(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func profileInfoRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    private func goalDisplayName(_ goal: String) -> String {
        switch goal.lowercased() {
        case "lose_weight":   return "减脂"
        case "gain_muscle":   return "增肌"
        case "maintain":      return "维持体重"
        case "improve_health": return "改善健康"
        default:              return goal
        }
    }

    private func activityLevelDisplayName(_ level: String) -> String {
        switch level.lowercased() {
        case "sedentary":     return "久坐（几乎不运动）"
        case "light", "lightly_active":
            return "轻度（每周 1-3 天）"
        case "moderate", "moderately_active":
            return "中度（每周 3-5 天）"
        case "active", "very_active":
            return "高度（每周 6-7 天）"
        case "extra_active":
            return "极高（体力劳动/运动员）"
        default:              return level
        }
    }

    // MARK: - 20.4 健康数据摘要

    private var healthSummarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "健康摘要", icon: "heart.text.square.fill")

            if isLoadingStats && nutritionStats == nil {
                HStack {
                    Spacer()
                    ProgressView().padding(.vertical, 20)
                    Spacer()
                }
            } else {
                HStack(spacing: 0) {
                    statCell(
                        value: nutritionStats.map { "\($0.totalDays)" } ?? "--",
                        label: "记录天数",
                        icon: "calendar"
                    )
                    Divider().frame(height: 40)
                    statCell(
                        value: nutritionStats.map { "\($0.totalRecords)" } ?? "--",
                        label: "食物次数",
                        icon: "fork.knife"
                    )
                    Divider().frame(height: 40)
                    statCell(
                        value: nutritionStats.map { "\(Int($0.avgCalories))" } ?? "--",
                        label: "平均卡路里",
                        icon: "flame.fill"
                    )
                }
                .padding(.vertical, 12)
            }
        }
        .cardBackground()
    }

    // MARK: - 20.5 等级/XP/进度条

    private func currentLevelStartXp(level: Int) -> Int {
        return 100 * level * level
    }

    private var xpLevelSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "等级 & 经验值", icon: "star.circle.fill")

            if let currentLevel, let totalXp {
                VStack(spacing: 14) {
                    // 等级徽章 + 总 XP
                    HStack(spacing: 12) {
                        // 等级徽章
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [AppTheme.primaryLight, AppTheme.primary],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 60, height: 60)
                            VStack(spacing: 1) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Lv.\(currentLevel)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .shadow(color: AppTheme.primary.opacity(0.4), radius: 6, x: 0, y: 3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("累计经验值")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text("\(totalXp)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("XP")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        Spacer()

                        // 满级标签 or 下一级提示
                        let remaining = gamificationManager.xpToNextLevel(totalXp: totalXp)
                        if remaining == 0 {
                            Text("已满级")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.primary.opacity(0.12)))
                        } else {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("距下一级")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("\(remaining) XP")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.warning)
                            }
                        }
                    }

                    // 进度条
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.primaryLight.opacity(0.35))
                                    .frame(height: 14)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(
                                        colors: [AppTheme.primaryLight, AppTheme.primary],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: geo.size.width * min(max(levelProgress, 0), 1.0), height: 14)
                                    .animation(.easeInOut(duration: 0.6), value: levelProgress)
                            }
                        }
                        .frame(height: 14)

                        // 当前等级 XP 范围
                        let levelStart = currentLevelStartXp(level: currentLevel)
                        let nextLevelXp = currentLevelStartXp(level: currentLevel + 1)
                        let xpInLevel = totalXp - levelStart
                        let xpForLevel = nextLevelXp - levelStart
                        let remaining2 = gamificationManager.xpToNextLevel(totalXp: totalXp)

                        HStack {
                            if remaining2 == 0 {
                                Text("MAX LEVEL")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AppTheme.primary)
                            } else {
                                Text("\(xpInLevel) / \(xpForLevel) XP")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            if remaining2 > 0 {
                                Text("Lv.\(currentLevel + 1) 需 \(nextLevelXp) XP")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textDisabled)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppTheme.textDisabled)
                    Text("等级数据同步中")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textDisabled)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .cardBackground()
    }

    // MARK: - 20.6 成就徽章网格

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader(title: "成就徽章", icon: "trophy.fill")
                Spacer()
                if totalAchievements > 0 {
                    let pct = Int(Double(unlockedCount) / Double(totalAchievements) * 100)
                    Text("\(unlockedCount)/\(totalAchievements) · \(pct)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.primary.opacity(0.10))
                        )
                        .padding(.trailing, 16)
                        .padding(.top, 14)
                }
            }

            if gamificationManager.achievements.isEmpty {
                emptyPlaceholder(icon: "trophy.fill", message: "成就加载中...")
            } else {
                AchievementGridView(
                    achievements: displayedAchievements,
                    totalCount: totalAchievements,
                    unlockedCount: unlockedCount
                )

                if shouldCollapseAchievements {
                    Button(action: { showAllAchievements.toggle() }) {
                        HStack(spacing: 6) {
                            Text(showAllAchievements ? "收起成就" : "查看全部 \(totalAchievements) 项成就")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: showAllAchievements ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.primaryDark)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.primary.opacity(0.10))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardBackground()
    }

    // MARK: - 20.7 联盟信息

    private var leagueSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                sectionHeader(title: "联盟", icon: "person.3.fill")
                Spacer()
                if gamificationManager.leagueSettlement != nil {
                    Button(action: { showLeagueSettlement = true }) {
                        Text("查看结算")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 14)
                }
            }

            if gamificationManager.isLoading && gamificationManager.leagueInfo == nil {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView().padding(.vertical, 20)
                    Spacer()
                }
            } else if let league = gamificationManager.leagueInfo {
                // ── 当前联盟 + 本周排名 + 本周 XP ──
                HStack(spacing: 0) {
                    leagueStatCell(
                        icon: "shield.fill",
                        value: leagueTierName(league.tier),
                        label: "当前联盟",
                        color: leagueTierColor(league.tier)
                    )
                    Divider().frame(height: 40)
                    leagueStatCell(
                        icon: "list.number",
                        value: "#\(league.userRank)",
                        label: "本周排名",
                        color: AppTheme.textPrimary
                    )
                    Divider().frame(height: 40)
                    leagueStatCell(
                        icon: "star.fill",
                        value: "\(league.userWeeklyXp) XP",
                        label: "本周经验",
                        color: AppTheme.secondary
                    )
                }
                .padding(.vertical, 12)

                // ── 联盟名称副标题 ──
                HStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12))
                        .foregroundColor(leagueTierColor(league.tier))
                    Text(leagueSubtitle(for: league))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("共 \(league.totalMembers) 名成员")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textDisabled)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                // ── Top 10 排行榜 ──
                if !league.topMembers.isEmpty {
                    Divider().padding(.horizontal, 16)

                    HStack {
                        Text("本周排行榜 Top 10")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                    VStack(spacing: 0) {
                        ForEach(league.topMembers.prefix(10)) { member in
                            leaderboardRow(member: member, currentUserId: userManager.currentUser.map { String($0.id) })
                            if member.rank < min(league.topMembers.prefix(10).last?.rank ?? 10, 10) {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            } else {
                // Empty state
                emptyPlaceholder(icon: "person.3.fill", message: "暂无联盟信息")
            }
        }
        .cardBackground()
    }

    // MARK: - Leaderboard Row

    private func leaderboardRow(member: LeagueMember, currentUserId: String?) -> some View {
        let isCurrentUser = member.userId == currentUserId
        return HStack(spacing: 12) {
            // Rank number
            rankBadge(rank: member.rank)

            ZStack {
                Circle()
                    .fill(AppTheme.primaryLight.opacity(0.28))
                    .frame(width: 36, height: 36)
                RaccoonMoodView(mood: petMood(for: member.petAvatarMood), size: 28)
            }

            // Nickname
            Text(member.nickname)
                .font(.system(size: 14, weight: isCurrentUser ? .bold : .regular))
                .foregroundColor(isCurrentUser ? AppTheme.primary : AppTheme.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Weekly XP
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.primary)
                Text("\(member.weeklyXp)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isCurrentUser
                ? AppTheme.primary.opacity(0.08)
                : Color.clear
        )
        .overlay(
            isCurrentUser
                ? RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(AppTheme.primary.opacity(0.2), lineWidth: 0)
                : nil
        )
    }

    private func rankBadge(rank: Int) -> some View {
        ZStack {
            Circle()
                .fill(rankBadgeColor(rank).opacity(rank <= 3 ? 0.22 : 1))
                .frame(width: 30, height: 30)
            Text("\(rank)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(rank <= 3 ? rankTextColor(rank) : AppTheme.textSecondary)
        }
        .frame(width: 30, height: 30)
    }

    private func petMood(for mood: String) -> PetMood {
        switch mood.lowercased() {
        case "happy":     return .happy
        case "satisfied": return .satisfied
        case "normal":    return .normal
        case "hungry":    return .hungry
        case "sad":       return .sad
        case "missing":   return .missing
        default:          return .normal
        }
    }

    // MARK: - 20.8 体重历史折线图

    private var weightHistorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row with latest weight + record count
            HStack {
                sectionHeader(title: "体重历史（近 30 天）", icon: "scalemass.fill")
                
                Spacer()
                if let latest = weightHistory.sorted(by: { $0.recordedAt < $1.recordedAt }).last {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f kg", latest.weight))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("最新")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 14)
                }
            }

            WeightLineChartView(records: weightHistory)
        }
        .cardBackground()
    }

    // MARK: - 20.10 联盟结算（任务 20.10）

    /// 加载结算结果，若存在未查看的结算则自动弹出
    private func loadSettlementIfNeeded(showPageError: Bool) async {
        do {
            guard let settlement = try await APIService.shared.getLeagueSettlement() else {
                gamificationManager.leagueSettlement = nil
                return
            }
            gamificationManager.leagueSettlement = settlement
            // Auto-show if not yet dismissed for this settlement
            let dismissKey = "leagueSettlementDismissed_\(settlement.finalRank)_\(settlement.newTier)"
            if !UserDefaults.standard.bool(forKey: dismissKey) {
                showLeagueSettlement = true
            }
        } catch {
            print("[ProfileView] loadSettlementIfNeeded error: \(error.localizedDescription)")
            if showPageError, errorMessage == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Shared UI Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.primary)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private func badgeView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(color)
            Text(text).font(.system(size: 12, weight: .semibold)).foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.12)))
    }

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(AppTheme.secondary)
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(AppTheme.textPrimary)
            Text(label).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func leagueStatCell(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func emptyPlaceholder(icon: String, message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 28)).foregroundColor(AppTheme.textDisabled)
                Text(message).font(.system(size: 13)).foregroundColor(AppTheme.textDisabled)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    private func leagueTierName(_ tier: String) -> String {
        switch tier.lowercased() {
        case "bronze":   return "青铜"
        case "silver":   return "白银"
        case "gold":     return "黄金"
        case "platinum": return "铂金"
        case "diamond":  return "钻石"
        default:         return tier
        }
    }

    private func leagueSubtitle(for league: LeagueInfo) -> String {
        switch league.tier.lowercased() {
        case "bronze":   return "青铜联盟"
        case "silver":   return "白银联盟"
        case "gold":     return "黄金联盟"
        case "platinum": return "铂金联盟"
        case "diamond":  return "钻石联盟"
        default:         return league.leagueName
        }
    }

    private func leagueTierColor(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "bronze":   return Color(red: 0.8, green: 0.5, blue: 0.2)
        case "silver":   return Color(red: 0.6, green: 0.6, blue: 0.65)
        case "gold":     return AppTheme.primary
        case "platinum": return Color(red: 0.4, green: 0.7, blue: 0.85)
        case "diamond":  return Color(red: 0.3, green: 0.6, blue: 1.0)
        default:         return AppTheme.textSecondary
        }
    }

    private func rankBadgeColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.72, green: 0.75, blue: 0.8)
        case 3: return Color(red: 0.78, green: 0.53, blue: 0.32)
        default: return AppTheme.backgroundSecondary
        }
    }

    private func rankTextColor(_ rank: Int) -> Color {
        rank <= 3 ? AppTheme.textPrimary : AppTheme.textSecondary
    }

    // MARK: - Data Loading

    private func loadAllData(showPageError: Bool) async {
        isLoading = true
        defer { isLoading = false }
        if showPageError {
            errorMessage = nil
        }

        async let profileTask: Void = loadProfile(showPageError: showPageError)
        async let gamificationTask: Void = gamificationManager.refreshStatus()
        async let weightTask: Void = loadWeightHistory(showPageError: showPageError && weightHistory.isEmpty)
        async let statsTask: Void = loadNutritionStats(showPageError: showPageError && nutritionStats == nil)
        _ = await (profileTask, gamificationTask, weightTask, statsTask)

        if showPageError, errorMessage == nil {
            errorMessage = gamificationManager.errorMessage
        }
    }

    private func loadProfile(showPageError: Bool) async {
        do {
            userProfile = try await APIService.shared.getProfile()
        } catch {
            print("[ProfileView] loadProfile error: \(error.localizedDescription)")
            if showPageError, errorMessage == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadWeightHistory(showPageError: Bool) async {
        do {
            weightHistory = try await APIService.shared.getWeightHistory()
        } catch {
            print("[ProfileView] loadWeightHistory error: \(error.localizedDescription)")
            if showPageError, errorMessage == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadNutritionStats(showPageError: Bool) async {
        isLoadingStats = true
        defer { isLoadingStats = false }
        do {
            // 获取全部时间的统计（365天），以展示累计数据
            nutritionStats = try await APIService.shared.getFoodStats(days: 365)
        } catch {
            print("[ProfileView] loadNutritionStats error: \(error.localizedDescription)")
            if showPageError, errorMessage == nil {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Card Background Modifier

private extension View {
    func cardBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.92), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 8)
        )
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
