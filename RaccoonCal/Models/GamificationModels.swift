//
//  GamificationModels.swift
//  RaccoonCal
//

import Foundation

// MARK: - 游戏化状态
struct GamificationStatus: Codable {
    let totalXp: Int
    let level: Int
    let weeklyXp: Int
    let currentHp: Int
    let streakDays: Int
    let streakShields: Int
    let xpToNextLevel: Int
    let levelProgress: Double // 0.0-1.0
}

// MARK: - XP 流水记录
struct XpTransaction: Codable {
    let id: Int
    let amount: Int
    let reason: String
    let refId: String?
    let earnedAt: String
}
