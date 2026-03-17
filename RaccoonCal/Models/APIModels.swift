//
//  APIModels.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/13.
//

import Foundation

// MARK: - 通用响应格式
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let error: APIError?
    let timestamp: String
}

struct APIError: Codable {
    let code: String
    let message: String
    let details: String?
}

// MARK: - 用户相关模型
struct User: Codable {
    let id: Int
    let username: String
    let email: String?
    let phone: String?
    let emailVerified: Bool?
    let phoneVerified: Bool?
    let createdAt: String?
}

struct AuthResponse: Codable {
    let user: User
    let token: String
}

// MARK: - 注册请求
struct RegisterRequest: Codable {
    let username: String
    let password: String
    let email: String?
    let phone: String?
}

// MARK: - 登录请求
struct LoginRequest: Codable {
    let identifier: String
    let password: String
}

// MARK: - 验证码相关
struct CaptchaResponse: Codable {
    let captchaId: String
    let captchaImage: String
}

struct CaptchaVerifyRequest: Codable {
    let captchaId: String
    let captchaCode: String
}

struct CaptchaVerifyResponse: Codable {
    let valid: Bool
}

// MARK: - 个人资料相关模型
struct UserProfile: Codable {
    let id: Int
    let userId: Int
    let nickname: String
    let gender: String
    let height: Double
    let weight: Double
    let age: Int
    let goal: String
    let activityLevel: String
    let dailyCalTarget: Int
    let createdAt: String
    let updatedAt: String
}

struct WeightRecord: Codable {
    let id: Int
    let weight: Double
    let recordedAt: String
}

struct ProfileUpdateRequest: Codable {
    let nickname: String?
    let gender: String?
    let height: Double?
    let weight: Double?
    let age: Int?
    let goal: String?
    let activityLevel: String?
}
