//
//  HomeView.swift
//  RaccoonCal
//
//  首页今日概览：
//  - 顶部信息栏（昵称 / Streak 火焰 / 等级）
//  - CalorieRingView 卡路里环形进度
//  - HPHeartView 生命值
//  - 三餐 + 加餐卡路里小计列表
//  - RaccoonMoodView 浣熊主场景（点击互动 + 随机鼓励文案）
//  - 每日任务进度区域（可展开）
//  - onAppear 拉取游戏化状态和今日饮食记录
//  - 超标时浣熊切换难过状态 + "今日已超标"提示
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    // MARK: - Dependencies

    @StateObject private var gamificationManager = GamificationManager.shared
    @StateObject private var userManager = UserManager.shared
    @EnvironmentObject private var appState: AppState

    // MARK: - Local State

    /// 今日饮食汇总
    @State private var dailyCalSummary: DailyCalSummary? = nil
    /// 个人资料（含每日卡路里目标和昵称）
    @State private var userProfile: UserProfile? = nil
    /// 是否正在加载饮食数据
    @State private var isLoadingFood: Bool = false
    /// 是否展开任务详情列表
    @State private var isTasksExpanded: Bool = false
    /// 当前显示的鼓励文案（点击浣熊后显示）
    @State private var encouragementText: String? = nil
    /// 是否显示鼓励文案气泡
    @State private var showEncouragement: Bool = false
    /// 是否正在执行互动请求
    @State private var isInteracting: Bool = false

    // MARK: - Computed Properties

    /// 今日总卡路里
    private var totalCalories: Double {
        dailyCalSummary?.totalCalories ?? 0
    }

    /// 每日卡路里目标
    private var dailyTarget: Double {
        Double(userProfile?.dailyCalTarget ?? 2000)
    }

    /// 是否超标（超出目标）
    private var isOverTarget: Bool {
        totalCalories > dailyTarget
    }

    /// 当前 HP
    private var currentHp: Int {
        gamificationManager.gamificationStatus?.currentHp ?? 5
    }

    /// 当前等级
    private var currentLevel: Int {
        gamificationManager.gamificationStatus?.level ?? 1
    }

    /// 连续打卡天数
    private var streakDays: Int {
        gamificationManager.gamificationStatus?.streakDays ?? 0
    }

    /// 昵称
    private var nickname: String {
        userProfile?.nickname ?? userManager.currentUser?.username ?? "浣熊用户"
    }

    /// 餐次分组列表（按固定顺序）
    private var mealGroups: [MealGroup] {
        let groups = dailyCalSummary?.mealGroups ?? []
        let order = ["breakfast", "lunch", "dinner", "snack"]
        return order.compactMap { key in groups.first { $0.mealType == key } }
    }

    /// 已完成任务数
    private var completedTaskCount: Int {
        gamificationManager.dailyTasks.filter { $0.completed }.count
    }

    /// 总任务数
    private var totalTaskCount: Int {
        gamificationManager.dailyTasks.count
    }

    /// 浣熊心情（本地计算）
    private var petMood: PetMood {
        // 超标时强制 sad（需求 16.9）
        if isOverTarget { return .sad }
        let mealCount = mealGroups.filter { !$0.records.isEmpty }.count
        return gamificationManager.calcPetMood(
            calories: totalCalories,
            target: dailyTarget,
            mealCount: mealCount,
            streakDays: streakDays
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.gradientBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // 16.2 顶部信息栏
                        topInfoBar

                        // 16.3 卡路里环形进度
                        calorieRingSection

                        // 16.4 生命值
                        hpSection

                        // 16.9 超标提示
                        if isOverTarget {
                            overTargetBanner
                        }

                        // 16.6 浣熊主场景
                        raccoonSection

                        // 16.5 三餐 + 加餐小计
                        mealSummarySection

                        // 16.7 每日任务进度
                        dailyTasksSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await loadData()
                }

                // XP 浮动标签
                if gamificationManager.isXpFloatVisible {
                    VStack {
                        Spacer()
                        XPFloatLabel(
                            amount: gamificationManager.xpFloatAmount,
                            isVisible: gamificationManager.isXpFloatVisible
                        )
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationTitle("今日概览")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadData()
        }
    }

    // MARK: - 16.2 顶部信息栏

    private var topInfoBar: some View {
        HStack(spacing: 12) {
            // 昵称
            Text(nickname)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            // Streak 火焰图标 + 天数
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(streakDays > 0 ? AppTheme.warning : AppTheme.textDisabled)
                    .font(.system(size: 16))
                Text("\(streakDays)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(streakDays > 0 ? AppTheme.warning : AppTheme.textDisabled)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill((streakDays > 0 ? AppTheme.warning : AppTheme.textDisabled).opacity(0.12))
            )

            // 等级徽章
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(AppTheme.primary)
                    .font(.system(size: 14))
                Text("Lv.\(currentLevel)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(AppTheme.primary.opacity(0.12))
            )
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    // MARK: - 16.3 卡路里环形进度

    private var calorieRingSection: some View {
        VStack(spacing: 8) {
            CalorieRingView(
                consumed: totalCalories,
                target: dailyTarget,
                lineWidth: 16,
                size: 180
            )

            if isOverTarget {
                Text("超出 \(Int(totalCalories - dailyTarget)) kcal")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.warning)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    // MARK: - 16.4 生命值

    private var hpSection: some View {
        HStack {
            Text("生命值")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            HPHeartView(hp: currentHp, heartSize: 22)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
        )
    }

    // MARK: - 16.9 超标提示横幅

    private var overTargetBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.warning)
            Text("今日已超标")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.warning)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.warning.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - 16.6 浣熊主场景

    private var raccoonSection: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))

            VStack(spacing: 12) {
                // 浣熊图片（点击触发互动）
                Button(action: handleRaccoonTap) {
                    RaccoonMoodView(mood: petMood, size: 140)
                        .scaleEffect(isInteracting ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isInteracting)
                }
                .buttonStyle(.plain)
                .disabled(isInteracting)

                // 鼓励文案气泡
                if showEncouragement, let text = encouragementText {
                    Text(text)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.primaryLight.opacity(0.5))
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 16.5 三餐 + 加餐小计

    private var mealSummarySection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("今日饮食")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                // 跳转记录页入口
                Button(action: { appState.selectedTab = 1 }) {
                    Text("查看全部")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 16)

            ForEach(MealType.allCases, id: \.self) { mealType in
                let group = mealGroups.first { $0.mealType == mealType.rawValue }
                Button(action: { appState.selectedTab = 1 }) {
                    mealRow(mealType: mealType, group: group)
                }
                .buttonStyle(.plain)

                if mealType != MealType.allCases.last {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }

            Spacer(minLength: 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    private func mealRow(mealType: MealType, group: MealGroup?) -> some View {
        HStack(spacing: 12) {
            // 餐次图标
            Image(systemName: mealTypeIcon(mealType))
                .font(.system(size: 18))
                .foregroundColor(AppTheme.primary)
                .frame(width: 28)

            // 餐次名称
            Text(mealTypeLabel(mealType))
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            // 卡路里小计
            Text("\(Int(group?.totalCalories ?? 0)) kcal")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(group != nil ? AppTheme.textPrimary : AppTheme.textDisabled)

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textDisabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 16.7 每日任务进度

    private var dailyTasksSection: some View {
        VStack(spacing: 0) {
            // 任务进度标题行（点击展开/收起）
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isTasksExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(completedTaskCount == totalTaskCount && totalTaskCount > 0
                            ? AppTheme.success : AppTheme.primary)

                    Text("每日任务")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    // 进度文字
                    Text("\(completedTaskCount)/\(totalTaskCount) 完成")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    Image(systemName: isTasksExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textDisabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // 任务进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.primaryLight.opacity(0.4))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.secondary)
                        .frame(
                            width: totalTaskCount > 0
                                ? geo.size.width * CGFloat(completedTaskCount) / CGFloat(totalTaskCount)
                                : 0,
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: completedTaskCount)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // 展开的任务详情列表
            if isTasksExpanded {
                Divider()
                    .padding(.horizontal, 16)

                if gamificationManager.dailyTasks.isEmpty {
                    Text("暂无任务数据")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textDisabled)
                        .padding(.vertical, 16)
                } else {
                    ForEach(gamificationManager.dailyTasks) { task in
                        taskRow(task: task)
                        if task.id != gamificationManager.dailyTasks.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }

            Spacer(minLength: 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    private func taskRow(task: DailyTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(task.completed ? AppTheme.success : AppTheme.textDisabled)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 14))
                    .foregroundColor(task.completed ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .strikethrough(task.completed)
            }

            Spacer()

            Text("+\(task.xpReward) XP")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(task.completed ? AppTheme.textDisabled : AppTheme.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill((task.completed ? AppTheme.textDisabled : AppTheme.primary).opacity(0.1))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 16.8 onAppear 数据加载

    private func loadData() async {
        // 并发拉取游戏化状态、今日饮食记录、个人资料
        async let gamificationTask: Void = gamificationManager.refreshStatus()
        async let foodTask: Void = loadFoodRecords()
        async let profileTask: Void = loadProfile()

        _ = await (gamificationTask, foodTask, profileTask)
    }

    private func loadFoodRecords() async {
        isLoadingFood = true
        defer { isLoadingFood = false }
        do {
            let today = todayDateString()
            dailyCalSummary = try await APIService.shared.getFoodRecords(date: today)
        } catch {
            print("[HomeView] loadFoodRecords error: \(error.localizedDescription)")
        }
    }

    private func loadProfile() async {
        do {
            userProfile = try await APIService.shared.getProfile()
        } catch {
            print("[HomeView] loadProfile error: \(error.localizedDescription)")
        }
    }

    // MARK: - 16.6 浣熊互动

    private func handleRaccoonTap() {
        guard !isInteracting else { return }
        isInteracting = true

        // 显示随机鼓励文案
        withAnimation(.easeInOut(duration: 0.2)) {
            encouragementText = randomEncouragement()
            showEncouragement = true
        }

        // 调用互动 API
        Task {
            do {
                let newStatus = try await APIService.shared.interactWithPet()
                // 更新游戏化状态并触发 XP 浮动动画
                let xpDiff = newStatus.totalXp - (gamificationManager.gamificationStatus?.totalXp ?? newStatus.totalXp)
                gamificationManager.gamificationStatus = newStatus
                if xpDiff > 0 {
                    gamificationManager.showXpFloat(amount: xpDiff)
                }
            } catch {
                print("[HomeView] interactWithPet error: \(error.localizedDescription)")
            }

            // 1.5 秒后隐藏文案，重置互动状态
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                showEncouragement = false
            }
            isInteracting = false
        }
    }

    // MARK: - Helpers

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func mealTypeLabel(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "早餐"
        case .lunch:     return "午餐"
        case .dinner:    return "晚餐"
        case .snack:     return "加餐"
        }
    }

    private func mealTypeIcon(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "sun.rise.fill"
        case .lunch:     return "sun.max.fill"
        case .dinner:    return "moon.fill"
        case .snack:     return "leaf.fill"
        }
    }

    private func randomEncouragement() -> String {
        let phrases: [String]
        switch petMood {
        case .happy:
            phrases = ["太棒了！今天的饮食很均衡 🎉", "你做到了！继续保持 💪", "完美！浣熊为你骄傲 ⭐️"]
        case .satisfied:
            phrases = ["不错哦，继续记录吧 😊", "已经记录了好几餐，加油！", "浣熊很满足，继续努力 🦝"]
        case .normal:
            phrases = ["今天才刚开始，加油记录！", "别忘了记录午餐和晚餐哦 🍱", "浣熊在等你的下一餐 🦝"]
        case .hungry:
            phrases = ["快去记录今天的第一餐吧！", "浣熊饿了，快去吃点东西 🍜", "开始记录，养成好习惯 💫"]
        case .sad:
            phrases = ["今天超标了，明天继续加油 💪", "没关系，明天会更好 🌟", "浣熊相信你能做到的 🦝"]
        case .missing:
            phrases = ["好久不见！浣熊很想你 🦝", "回来了！快记录今天的饮食吧", "欢迎回来，一起继续健康之旅 🌿"]
        }
        return phrases.randomElement() ?? "加油！浣熊为你加油 🦝"
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(AppState.shared)
}
