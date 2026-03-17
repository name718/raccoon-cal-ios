//
//  AchievementModels.swift
//  RaccoonCal

import Foundation

// MARK: - 成就

struct Achievement: Codable, Identifiable {
    let key: String
    let title: String
    let description: String
    let xpReward: Int
    let iconName: String
    let unlocked: Bool
    let unlockedAt: String?

    // Identifiable 使用 key
    var id: String { key }
}
