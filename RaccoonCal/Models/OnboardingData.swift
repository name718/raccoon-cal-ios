//
//  OnboardingData.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import Foundation

struct OnboardingData: Codable {
    var nickname: String = ""
    var gender: String = ""
    var height: Int = 170
    var weight: Int = 60
    var age: Int = 25
    var goal: String = ""
    var goalDuration: String = ""
    var activityLevel: String = ""
    var waterIntake: String = ""
    var sleepTime: String = ""
    var favoriteFood: [String] = []
    var socialPreference: String = ""
    var mealsPerDay: String = ""
    var cookingStyle: String = ""
    var dietaryRestrictions: [String] = []
    var petName: String = "小R"
    
    // 保存到本地
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "OnboardingData")
        }
    }
    
    // 从本地读取
    static func load() -> OnboardingData? {
        if let data = UserDefaults.standard.data(forKey: "OnboardingData"),
           let decoded = try? JSONDecoder().decode(OnboardingData.self, from: data) {
            return decoded
        }
        return nil
    }
    
    // 清除数据
    static func clear() {
        UserDefaults.standard.removeObject(forKey: "OnboardingData")
    }
}
