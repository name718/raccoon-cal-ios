//
//  FoodModels.swift
//  RaccoonCal
//

import Foundation

// MARK: - 食物识别

/// 单个识别食物结果
struct RecognizedFood: Codable {
    let name: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let servingSize: Double
}

/// 食物识别响应
struct FoodRecognitionResult: Codable, Identifiable {
    /// Synthetic id so this can be used with `.sheet(item:)`
    var id: UUID = UUID()
    let foods: [RecognizedFood]
    let confidence: Double

    // Keep UUID out of JSON encoding/decoding
    enum CodingKeys: String, CodingKey {
        case foods, confidence
    }
}

// MARK: - 饮食记录

/// 餐次类型
enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
}

/// 单条饮食记录
struct FoodRecord: Codable, Identifiable {
    let id: Int
    let foodName: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let fiber: Double
    let servingSize: Double
    let mealType: String
    let imageUrl: String?
    let recordedAt: String
}

// MARK: - 餐次分组

/// 按餐次分组的饮食记录
struct MealGroup: Codable {
    let mealType: String
    let totalCalories: Double
    let totalProtein: Double
    let totalFat: Double
    let totalCarbs: Double
    let records: [FoodRecord]
}

/// 每日卡路里汇总
struct DailyCalSummary: Codable {
    let date: String
    let totalCalories: Double
    let mealGroups: [MealGroup]
}

// MARK: - 保存饮食记录请求

struct SaveFoodRecordRequest: Codable {
    let foodName: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let fiber: Double
    let servingSize: Double
    let mealType: String
    let imageUrl: String?
    let recordedAt: String?
}

// MARK: - 营养统计

/// 单日卡路里数据点（用于折线图）
struct DailyCalories: Codable {
    let date: String
    let calories: Double
}

/// N 天营养统计
struct NutritionStats: Codable {
    let dailyCalories: [DailyCalories]
    let avgProtein: Double
    let avgFat: Double
    let avgCarbs: Double
    /// 有饮食记录的天数
    let totalDays: Int
    /// 饮食记录总条数
    let totalRecords: Int
    /// 有记录天数的平均卡路里
    let avgCalories: Double
}
