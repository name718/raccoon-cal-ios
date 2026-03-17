//
//  TaskModels.swift
//  RaccoonCal
//

import Foundation

// MARK: - 每日任务

/// 单条每日任务
struct DailyTask: Codable, Identifiable {
    let id: Int
    let taskKey: String
    let title: String
    let xpReward: Int
    let completed: Bool
    let completedAt: String?
    let taskDate: String
}

/// GET /api/tasks/daily 响应体
struct DailyTasksResponse: Codable {
    let tasks: [DailyTask]
    let allCompleted: Bool
    let completedCount: Int
    let bonusAwarded: Bool
}

/// POST /api/tasks/:id/complete 响应体
struct TaskCompleteResult: Codable {
    let taskId: Int?
    let xpAwarded: Int?
    let alreadyCompleted: Bool?
}
