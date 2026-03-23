//
//  RecordView.swift
//  RaccoonCal
//
//  历史记录页：
//  - 18.2 日历视图（过去 30 天打卡状态，已打卡用主色标记）
//  - 18.3 点击日期展示该日饮食记录列表（按餐次分组）
//  - 18.4 长按记录弹出删除确认，删除后重新计算当日卡路里
//  - 18.5 过去 7 天卡路里折线图（含目标虚线）
//  - 18.6 过去 7 天三大营养素柱状图
//  - 18.7 下拉刷新重新拉取数据
//  - 18.8 无记录时的引导文案和跳转 CameraView 按钮
//

import SwiftUI

// MARK: - RecordView

struct RecordView: View {

    // MARK: - Dependencies

    @StateObject private var gamificationManager = GamificationManager.shared
    @EnvironmentObject private var appState: AppState

    // MARK: - Local State

    /// 当前选中的日期（默认今天）
    @State private var selectedDate: Date = Date()

    /// 选中日期的饮食记录汇总（按餐次分组）
    @State private var dailyCalSummary: DailyCalSummary? = nil

    /// 过去 7 天营养统计（折线图 + 柱状图数据源）
    @State private var nutritionStats: NutritionStats? = nil

    /// 过去 30 天有打卡记录的日期集合（用于日历标记）
    @State private var checkedInDates: Set<String> = []

    /// 是否正在加载记录数据
    @State private var isLoading: Bool = false

    /// 是否正在加载统计数据
    @State private var isLoadingStats: Bool = false

    /// 待删除的饮食记录（非 nil 时弹出删除确认）
    @State private var recordToDelete: FoodRecord? = nil

    /// 是否显示删除确认弹窗
    @State private var showDeleteConfirm: Bool = false

    /// 删除失败时的错误信息（非 nil 时弹出错误提示）
    @State private var deleteErrorMessage: String? = nil
    /// 页面加载失败时的错误信息
    @State private var loadErrorMessage: String? = nil

    /// 个人资料（含每日卡路里目标）
    @State private var userProfile: UserProfile? = nil

    // MARK: - Computed Properties

    /// 每日卡路里目标
    private var dailyTarget: Double {
        guard let dailyCalTarget = userProfile?.dailyCalTarget else { return 0 }
        return Double(dailyCalTarget)
    }

    /// 选中日期的字符串（yyyy-MM-dd）
    private var selectedDateString: String {
        dateString(from: selectedDate)
    }

    /// 选中日期的饮食记录是否为空
    private var hasRecordsForSelectedDate: Bool {
        guard let summary = dailyCalSummary else { return false }
        return summary.mealGroups.contains { !$0.records.isEmpty }
    }

    /// 按固定顺序排列的餐次分组
    private var orderedMealGroups: [MealGroup] {
        let groups = dailyCalSummary?.mealGroups ?? []
        let order = ["breakfast", "lunch", "dinner", "snack"]
        return order.compactMap { key in groups.first { $0.mealType == key } }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.gradientBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // 18.2 日历视图
                        calendarSection

                        // 18.3 选中日期的饮食记录列表（占位，Task 18.3 实现）
                        if hasRecordsForSelectedDate {
                            foodRecordsSection
                        } else {
                            // 18.8 无记录引导
                            emptyStateSection
                        }

                        // 18.5 过去 7 天卡路里折线图（占位，Task 18.5 实现）
                        calorieChartSection

                        // 18.6 过去 7 天三大营养素柱状图（占位，Task 18.6 实现）
                        macroChartSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                // 18.7 下拉刷新
                .refreshable {
                    await loadAll()
                }

                // 加载指示器
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.05))
                }

                Color.clear
                    .frame(width: 0, height: 0)
                    .appDialog(
                        isPresented: Binding(
                            get: { loadErrorMessage != nil },
                            set: { if !$0 { loadErrorMessage = nil } }
                        ),
                        title: "加载失败",
                        message: loadErrorMessage ?? "",
                        tone: .error,
                        primaryAction: AppDialogAction("确定") { loadErrorMessage = nil }
                    )
            }
            .navigationTitle("饮食记录")
            .navigationBarTitleDisplayMode(.inline)
        }
        .appDialog(
            isPresented: $showDeleteConfirm,
            title: "删除记录",
            message: recordToDelete.map { "确定要删除「\($0.foodName)」吗？删除后将重新计算当日卡路里。" } ?? "",
            tone: .warning,
            primaryAction: AppDialogAction("删除", role: .destructive) {
                if let record = recordToDelete {
                    Task { await deleteRecord(record) }
                }
            },
            secondaryAction: AppDialogAction("取消", role: .cancel) {
                recordToDelete = nil
            }
        )
        .appDialog(
            isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            ),
            title: "删除失败",
            message: deleteErrorMessage ?? "",
            tone: .error,
            primaryAction: AppDialogAction("确定") { deleteErrorMessage = nil }
        )
        .delayedLoadingOverlay(
            isLoading: isLoading || isLoadingStats,
            message: "正在加载饮食记录..."
        )
        .task {
            await loadAll()
        }
    }

    // MARK: - 18.2 日历视图（过去 30 天打卡状态）

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("打卡日历")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                // 图例
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 8, height: 8)
                    Text("已打卡")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            calendarGrid

            Spacer(minLength: 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    /// 过去 30 天日历网格：已打卡用主色填充，选中日期用主色背景+白字，今天加粗
    private var calendarGrid: some View {
        let calendar = Calendar.current
        let today = Date()
        let days: [Date] = (0..<30).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.reversed()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { day in
                let ds = dateString(from: day)
                let isCheckedIn = checkedInDates.contains(ds)
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(day)

                Button(action: {
                    selectedDate = day
                    Task { await loadRecords(for: day) }
                }) {
                    ZStack {
                        // 已打卡背景（浅色）
                        if isCheckedIn && !isSelected {
                            Circle()
                                .fill(AppTheme.primaryLight.opacity(0.45))
                                .frame(width: 32, height: 32)
                        }
                        // 选中背景（主色实心）
                        if isSelected {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 32, height: 32)
                        }
                        Text("\(calendar.component(.day, from: day))")
                            .font(.system(size: 13, weight: isToday ? .bold : .regular))
                            .foregroundColor(
                                isSelected  ? .white :
                                isCheckedIn ? AppTheme.primaryDark :
                                isToday     ? AppTheme.primaryDark :
                                              AppTheme.textSecondary
                            )
                    }
                    .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 18.3 饮食记录列表（按餐次分组）

    private var foodRecordsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text(formattedSelectedDate)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                if let summary = dailyCalSummary {
                    Text("\(Int(summary.totalCalories)) kcal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 16)

            // 按餐次分组展示饮食记录，每条记录支持长按触发删除确认（Task 18.4）
            ForEach(orderedMealGroups, id: \.mealType) { group in
                if !group.records.isEmpty {
                    mealGroupSection(group: group)
                }
            }

            Spacer(minLength: 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    private func mealGroupSection(group: MealGroup) -> some View {
        VStack(spacing: 0) {
            // 餐次标题行
            HStack {
                Image(systemName: mealTypeIcon(group.mealType))
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.primary)
                Text(mealTypeLabel(group.mealType))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(group.totalCalories)) kcal")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.primaryLight.opacity(0.15))

            // 记录列表
            ForEach(group.records) { record in
                foodRecordRow(record: record)
                    // 18.4 长按触发删除确认
                    .onLongPressGesture {
                        recordToDelete = record
                        showDeleteConfirm = true
                    }

                if record.id != group.records.last?.id {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
    }

    private func foodRecordRow(record: FoodRecord) -> some View {
        HStack(spacing: 12) {
            if let imageUrl = record.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.backgroundSecondary)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(AppTheme.textSecondary)
                        )
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(record.foodName)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textPrimary)
                Text("\(Int(record.servingSize))g · 蛋白质 \(String(format: "%.1f", record.protein))g · 脂肪 \(String(format: "%.1f", record.fat))g · 碳水 \(String(format: "%.1f", record.carbs))g")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(Int(record.calories)) kcal")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 18.5 卡路里折线图（scaffold，Task 18.5 填充实现）

    private var calorieChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("近 7 天卡路里")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                if isLoadingStats {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Task 18.5 — 折线图（含目标虚线）
            CalorieLineChartView(
                dataPoints: nutritionStats?.dailyCalories ?? [],
                dailyTarget: dailyTarget
            )

            Spacer(minLength: 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    // MARK: - 18.6 营养素柱状图

    private var macroChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("近 7 天营养素均值")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                if isLoadingStats {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Task 18.6 — 三大营养素柱状图（蛋白质 / 脂肪 / 碳水日均值）
            NutrientBarChartView(
                avgProtein: nutritionStats?.avgProtein ?? 0,
                avgFat:     nutritionStats?.avgFat     ?? 0,
                avgCarbs:   nutritionStats?.avgCarbs   ?? 0
            )

            Spacer(minLength: 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    // MARK: - 18.8 无记录引导

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image("RaccoonThinking")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text(isLoading ? "加载中..." : "这天还没有饮食记录")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            if !isLoading {
                Text("添加今天的饮食记录，养成稳定的健康习惯。")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textDisabled)
                    .multilineTextAlignment(.center)

                Button(action: { appState.presentAddEntryOptions() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("去添加记录")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(AppTheme.gradientPrimary)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    // MARK: - Data Loading

    /// 并发加载所有数据
    private func loadAll() async {
        loadErrorMessage = nil
        async let recordsTask: Void = loadRecords(for: selectedDate)
        async let statsTask: Void = loadStats()
        async let profileTask: Void = loadProfile()
        async let checkinTask: Void = loadCheckinDates()
        _ = await (recordsTask, statsTask, profileTask, checkinTask)
    }

    /// 加载指定日期的饮食记录
    private func loadRecords(for date: Date) async {
        isLoading = true
        defer { isLoading = false }
        do {
            dailyCalSummary = try await APIService.shared.getFoodRecords(date: dateString(from: date))
        } catch {
            print("[RecordView] loadRecords error: \(error.localizedDescription)")
            dailyCalSummary = nil
            if loadErrorMessage == nil { loadErrorMessage = error.localizedDescription }
        }
    }

    /// 加载过去 7 天营养统计
    private func loadStats() async {
        isLoadingStats = true
        defer { isLoadingStats = false }
        do {
            nutritionStats = try await APIService.shared.getFoodStats(days: 7)
        } catch {
            print("[RecordView] loadStats error: \(error.localizedDescription)")
            if loadErrorMessage == nil { loadErrorMessage = error.localizedDescription }
        }
    }

    /// 加载个人资料（含每日卡路里目标）
    private func loadProfile() async {
        do {
            userProfile = try await APIService.shared.getProfile()
        } catch {
            print("[RecordView] loadProfile error: \(error.localizedDescription)")
            if loadErrorMessage == nil { loadErrorMessage = error.localizedDescription }
        }
    }

    /// 加载过去 30 天打卡日期集合（从 7 天统计推断，Task 18.2 可扩展为专用接口）
    private func loadCheckinDates() async {
        do {
            // 拉取 30 天统计，将有卡路里记录的日期加入集合
            let stats = try await APIService.shared.getFoodStats(days: 30)
            let dates = stats.dailyCalories
                .filter { $0.calories > 0 }
                .map { $0.date }
            checkedInDates = Set(dates)
        } catch {
            print("[RecordView] loadCheckinDates error: \(error.localizedDescription)")
            if loadErrorMessage == nil { loadErrorMessage = error.localizedDescription }
        }
    }

    // MARK: - 18.4 删除记录

    /// 删除饮食记录并重新加载当日数据（重算卡路里）
    private func deleteRecord(_ record: FoodRecord) async {
        do {
            try await APIService.shared.deleteFoodRecord(id: record.id)
            // 删除成功后重新拉取当日记录（重算卡路里）
            await loadRecords(for: selectedDate)
            // 同步更新打卡日期集合
            await loadCheckinDates()
        } catch {
            print("[RecordView] deleteRecord error: \(error.localizedDescription)")
            deleteErrorMessage = error.localizedDescription
        }
        recordToDelete = nil
    }

    // MARK: - Helpers

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: selectedDate)
    }

    private func shortDateLabel(_ dateStr: String) -> String {
        // "2024-01-15" → "1/15"
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3 else { return dateStr }
        return "\(parts[1])/\(parts[2])"
    }

    private func mealTypeLabel(_ type: String) -> String {
        switch type {
        case "breakfast": return "早餐"
        case "lunch":     return "午餐"
        case "dinner":    return "晚餐"
        case "snack":     return "加餐"
        default:          return type
        }
    }

    private func mealTypeIcon(_ type: String) -> String {
        switch type {
        case "breakfast": return "sun.rise.fill"
        case "lunch":     return "sun.max.fill"
        case "dinner":    return "moon.fill"
        case "snack":     return "leaf.fill"
        default:          return "fork.knife"
        }
    }
}

// MARK: - Preview

#Preview {
    RecordView()
        .environmentObject(AppState.shared)
}
