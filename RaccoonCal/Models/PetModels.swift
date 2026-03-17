//
//  PetModels.swift
//  RaccoonCal

import Foundation

// MARK: - 宠物心情

/// 浣熊心情状态（与服务端 PetMood 对应）
enum PetMood: String, Codable, CaseIterable {
    case happy      // 开心：卡路里达标 90%-110%
    case satisfied  // 满足：记录 ≥ 2 餐
    case normal     // 正常：记录 1 餐
    case hungry     // 饥饿：无记录
    case sad        // 难过：超出目标 20%
    case missing    // 思念：连续 3 天未打卡

    /// 对应 Assets.xcassets 中的图片名称
    var imageName: String {
        switch self {
        case .happy:     return "RaccoonHappy"
        case .satisfied: return "RaccoonGreeting"
        case .normal:    return "RaccoonThinking"
        case .hungry:    return "RaccoonLoading"
        case .sad:       return "RaccoonExcited"
        case .missing:   return "RaccoonLoading"
        }
    }
}

// MARK: - 宠物状态

/// 宠物完整状态（对应 GET /api/pet 响应）
struct PetStatus: Codable {
    let id: Int
    let name: String
    let satiety: Double     // 饱食度 0-100
    let mood: PetMood
    let hatSlot: String?    // 帽子装扮 key
    let clothSlot: String?  // 衣服装扮 key
    let accessSlot: String? // 配件装扮 key
    let level: Int          // 来自 GamificationStatus
    let totalXp: Int        // 来自 GamificationStatus
}

// MARK: - 宠物升级事件

/// 宠物升级历史记录（对应 PetLevelHistory 表）
struct PetLevelEvent: Codable, Identifiable {
    let id: Int
    let level: Int
    let unlockedItem: String?   // 解锁的装扮 key，可选
    let achievedAt: String      // ISO 8601 时间字符串
}

// MARK: - 装扮

/// 装扮更新请求体（对应 PUT /api/pet/outfit）
struct PetOutfitRequest: Codable {
    let hat: String?
    let clothes: String?
    let accessory: String?
}
