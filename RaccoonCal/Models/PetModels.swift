//
//  PetModels.swift
//  RaccoonCal

import Foundation
import SwiftUI

// MARK: - 装扮槽位

/// 装扮槽位类型（帽子/衣服/配件）
enum OutfitSlot: String, CaseIterable {
    case hat       = "帽子"
    case clothes   = "衣服"
    case accessory = "配件"
}

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

    /// 心情中文描述
    var displayName: String {
        switch self {
        case .happy:     return "今天状态很棒"
        case .satisfied: return "吃得很满足"
        case .normal:    return "状态正常"
        case .hungry:    return "有点饿了"
        case .sad:       return "今天有点超标"
        case .missing:   return "好久不见"
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

// MARK: - 装扮目录（客户端静态数据）

/// 单件装扮道具（客户端静态目录条目）
struct OutfitItem: Identifiable {
    let id: String          // 与服务端 key 对应，如 "hat_basic"
    let slot: OutfitSlot    // 所属槽位
    let displayName: String // 中文名称
    let icon: String        // SF Symbol 名称（占位图标）
    let color: Color        // 占位颜色
    let requiredLevel: Int  // 解锁所需等级（用于展示锁定状态）
}

/// 客户端静态装扮目录（后端只返回已解锁 key，完整展示信息在客户端维护）
struct OutfitCatalog {
    static let all: [OutfitItem] = [
        // 帽子
        OutfitItem(id: "hat_basic",    slot: .hat,       displayName: "小草帽",   icon: "hat.widebrim",          color: .brown,  requiredLevel: 1),
        OutfitItem(id: "hat_party",    slot: .hat,       displayName: "派对帽",   icon: "party.popper",          color: .pink,   requiredLevel: 5),
        OutfitItem(id: "hat_crown",    slot: .hat,       displayName: "小皇冠",   icon: "crown.fill",            color: .yellow, requiredLevel: 10),
        OutfitItem(id: "hat_chef",     slot: .hat,       displayName: "厨师帽",   icon: "fork.knife",            color: .white,  requiredLevel: 15),
        OutfitItem(id: "hat_wizard",   slot: .hat,       displayName: "魔法帽",   icon: "wand.and.stars",        color: .purple, requiredLevel: 20),
        // 衣服
        OutfitItem(id: "cloth_basic",  slot: .clothes,   displayName: "条纹衫",   icon: "tshirt.fill",           color: .blue,   requiredLevel: 1),
        OutfitItem(id: "cloth_sport",  slot: .clothes,   displayName: "运动服",   icon: "figure.run",            color: .green,  requiredLevel: 5),
        OutfitItem(id: "cloth_suit",   slot: .clothes,   displayName: "小西装",   icon: "briefcase.fill",        color: .gray,   requiredLevel: 10),
        OutfitItem(id: "cloth_chef",   slot: .clothes,   displayName: "厨师服",   icon: "fork.knife.circle.fill",color: .white,  requiredLevel: 15),
        OutfitItem(id: "cloth_royal",  slot: .clothes,   displayName: "皇家袍",   icon: "crown",                 color: .purple, requiredLevel: 20),
        // 配件
        OutfitItem(id: "acc_glasses",  slot: .accessory, displayName: "圆框眼镜", icon: "eyeglasses",            color: .orange, requiredLevel: 1),
        OutfitItem(id: "acc_bow",      slot: .accessory, displayName: "蝴蝶结",   icon: "gift.fill",             color: .pink,   requiredLevel: 5),
        OutfitItem(id: "acc_medal",    slot: .accessory, displayName: "金牌",     icon: "medal.fill",            color: .yellow, requiredLevel: 10),
        OutfitItem(id: "acc_scarf",    slot: .accessory, displayName: "围巾",     icon: "wind",                  color: .red,    requiredLevel: 15),
        OutfitItem(id: "acc_wings",    slot: .accessory, displayName: "小翅膀",   icon: "bird.fill",             color: .cyan,   requiredLevel: 20),
    ]

    static func items(for slot: OutfitSlot) -> [OutfitItem] {
        all.filter { $0.slot == slot }
    }
}
