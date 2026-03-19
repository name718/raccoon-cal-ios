//
//  GamificationManager.swift
//  RaccoonCal
//

import Foundation
import Combine
import SwiftUI

@MainActor
class GamificationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = GamificationManager()

    // MARK: - Dependencies

    private let apiService = APIService.shared

    // MARK: - @Published Properties

    @Published var gamificationStatus: GamificationStatus?
    @Published var petStatus: PetStatus?
    @Published var petLevelHistory: [PetLevelEvent] = []
    @Published var dailyTasks: [DailyTask] = []
    @Published var achievements: [Achievement] = []
    @Published var leagueInfo: LeagueInfo?
    @Published var leagueSettlement: LeagueSettlement?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - XP Float Animation State (Task 13.4)

    /// 当前浮动 XP 数量，非零时触发动画
    @Published var xpFloatAmount: Int = 0
    /// 控制浮动标签是否可见
    @Published var isXpFloatVisible: Bool = false

    // MARK: - Init

    private init() {}

    func resetState() {
        gamificationStatus = nil
        petStatus = nil
        petLevelHistory = []
        dailyTasks = []
        achievements = []
        leagueInfo = nil
        leagueSettlement = nil
        isLoading = false
        errorMessage = nil
        xpFloatAmount = 0
        isXpFloatVisible = false
    }

    // MARK: - Refresh Status (Task 13.3)

    /// 从服务器拉取游戏化状态，并更新所有 @Published 属性
    func refreshStatus() async {
        isLoading = true
        errorMessage = nil

        async let statusResult = apiService.getGamificationStatus()
        async let tasksResult = apiService.getDailyTasks()
        async let achievementsResult = apiService.getAchievements()
        async let leagueResult = apiService.getLeague()

        do {
            gamificationStatus = try await statusResult
        } catch {
            print("[GamificationManager] refreshStatus - getGamificationStatus error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        do {
            let tasksResponse = try await tasksResult
            dailyTasks = tasksResponse.tasks
        } catch {
            print("[GamificationManager] refreshStatus - getDailyTasks error: \(error.localizedDescription)")
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }

        do {
            achievements = try await achievementsResult
        } catch {
            print("[GamificationManager] refreshStatus - getAchievements error: \(error.localizedDescription)")
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }

        do {
            leagueInfo = try await leagueResult
        } catch {
            print("[GamificationManager] refreshStatus - getLeague error: \(error.localizedDescription)")
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }

        isLoading = false
    }

    // MARK: - XP Float Animation (Task 13.4)

    /// 触发浮动 "+N XP" 动画，显示 1.5 秒后自动隐藏
    func showXpFloat(amount: Int) {
        guard amount > 0 else { return }
        xpFloatAmount = amount
        withAnimation(.easeOut(duration: 0.3)) {
            isXpFloatVisible = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeIn(duration: 0.3)) {
                isXpFloatVisible = false
            }
        }
    }

    // MARK: - Pet Mood Calculation (Task 13.5)

    /// 本地计算浣熊心情状态（与服务端 calcPetMood 逻辑保持一致）
    ///
    /// 规则：
    /// - streakDays == 0 且 mealCount == 0 → .missing
    /// - calories > target × 1.2           → .sad
    /// - calories ∈ [target×0.9, target×1.1] → .happy
    /// - mealCount ≥ 2                      → .satisfied
    /// - mealCount == 1                     → .normal
    /// - 其他                               → .hungry
    func calcPetMood(calories: Double, target: Double, mealCount: Int, streakDays: Int) -> PetMood {
        if streakDays == 0 && mealCount == 0 { return .missing }
        if calories > target * 1.2 { return .sad }
        if target > 0 && calories >= target * 0.9 && calories <= target * 1.1 { return .happy }
        if mealCount >= 2 { return .satisfied }
        if mealCount == 1 { return .normal }
        return .hungry
    }

    // MARK: - Pet Methods (Task 13.5)

    /// 从服务器拉取宠物状态（含饱食度/心情），更新 petStatus
    func loadPetStatus() async {
        do {
            petStatus = try await apiService.getPetStatus()
        } catch {
            print("[GamificationManager] loadPetStatus error: \(error.localizedDescription)")
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }
    }

    /// 从服务器拉取宠物升级历史（按 achievedAt 升序），更新 petLevelHistory
    func loadPetLevelHistory() async {
        do {
            let history = try await apiService.getPetLevelHistory()
            petLevelHistory = history.sorted { $0.achievedAt < $1.achievedAt }
        } catch {
            print("[GamificationManager] loadPetLevelHistory error: \(error.localizedDescription)")
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }
    }

    // MARK: - Pet Interaction (Task 19.4)

    /// 与浣熊互动（每日一次）。
    /// - Returns: 若本次成功互动则返回响应数据；若今日已互动则返回 nil
    func interactWithPet() async -> PetInteractResponse? {
        do {
            let result = try await apiService.interactWithPet()
            if result.alreadyInteracted {
                return nil
            }

            async let statusResult = apiService.getGamificationStatus()
            async let petResult = apiService.getPetStatus()

            gamificationStatus = try await statusResult
            petStatus = try await petResult
            showXpFloat(amount: result.xpAwarded)
            return result
        } catch {
            print("[GamificationManager] interactWithPet error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Pet Outfit (Task 19.6)

    /// 更换装扮：乐观更新本地 petStatus，调用 API 保存，失败时回滚。
    /// - Parameter outfit: 新装扮槽位请求体
    /// - Returns: 更新后的 PetStatus，失败时返回 nil
    func updatePetOutfit(_ outfit: PetOutfitRequest) async -> PetStatus? {
        // 保存旧状态用于回滚
        let previousStatus = petStatus

        // 乐观更新本地状态
        if let current = petStatus {
            petStatus = PetStatus(
                id: current.id,
                name: current.name,
                satiety: current.satiety,
                mood: current.mood,
                hatSlot: outfit.hat ?? current.hatSlot,
                clothSlot: outfit.clothes ?? current.clothSlot,
                accessSlot: outfit.accessory ?? current.accessSlot,
                level: current.level,
                totalXp: current.totalXp
            )
        }

        do {
            let updated = try await apiService.updatePetOutfit(outfit)
            petStatus = updated
            return updated
        } catch {
            // 回滚到旧状态
            petStatus = previousStatus
            print("[GamificationManager] updatePetOutfit error: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Level Calculation (Task 13.6)

    /// 根据累计 XP 计算当前等级（与服务端 calcLevel 逻辑一致）。
    /// 等级公式：Level N 所需累计 XP = 100 × N²，上限 50 级，最低 1 级。
    func calcLevel(totalXp: Int) -> Int {
        let level = Int(sqrt(Double(max(0, totalXp)) / 100.0))
        return min(max(level, 1), 50)
    }

    /// 计算升到下一级还需要多少 XP（与服务端 xpToNextLevel 逻辑一致）。
    /// 已满级（50 级）时返回 0。
    func xpToNextLevel(totalXp: Int) -> Int {
        let currentLevel = calcLevel(totalXp: totalXp)
        guard currentLevel < 50 else { return 0 }
        let nextLevelXp = 100 * (currentLevel + 1) * (currentLevel + 1)
        return nextLevelXp - max(0, totalXp)
    }

    // MARK: - Task Methods (Task 13.6)
    // TODO: 13.6 — Add methods:
    //   func loadDailyTasks() async
    //   func completeTask(id: Int) async

    // MARK: - Satiety Delta Calculation (Task 13.7)

    /// 计算本次饮食记录带来的饱食度增量（与服务端 calcSatietyDelta 逻辑一致）。
    ///
    /// 公式：`min(recordCalories / dailyTarget × 100, 100)`
    ///
    /// - Parameters:
    ///   - recordCalories: 本次记录的卡路里
    ///   - dailyTarget: 每日卡路里目标
    /// - Returns: 饱食度增量，范围 [0, 100]
    func calcSatietyDelta(recordCalories: Double, dailyTarget: Double) -> Double {
        guard dailyTarget > 0 else { return 0 }
        return min((recordCalories / dailyTarget) * 100, 100)
    }
}
