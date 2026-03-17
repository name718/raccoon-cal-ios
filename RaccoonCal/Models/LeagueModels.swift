//
//  LeagueModels.swift
//  RaccoonCal

import Foundation

// MARK: - 联盟成员

struct LeagueMember: Codable, Identifiable {
    let userId: String
    let nickname: String
    let petAvatarMood: String
    let weeklyXp: Int
    let rank: Int

    var id: String { userId }
}

// MARK: - 联盟信息

struct LeagueInfo: Codable {
    let leagueId: Int
    let leagueName: String
    let tier: String
    let userRank: Int
    let userWeeklyXp: Int
    let topMembers: [LeagueMember]
    let totalMembers: Int
}

// MARK: - 联盟结算结果

struct LeagueSettlement: Codable {
    let promoted: Bool?
    let demoted: Bool?
    let newTier: String
    let finalRank: Int
}
