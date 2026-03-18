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

    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case details
    }

    init(code: String, message: String, details: String?) {
        self.code = code
        self.message = message
        self.details = details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)

        if let detailString = try? container.decode(String.self, forKey: .details) {
            details = detailString
        } else if let detailPayload = try? container.decode(APIErrorDetails.self, forKey: .details) {
            let messages = detailPayload.errors.map(\.message)
            let uniqueMessages = messages.reduce(into: [String]()) { result, message in
                if !result.contains(message) {
                    result.append(message)
                }
            }
            details = uniqueMessages.isEmpty ? nil : uniqueMessages.joined(separator: "\n")
        } else {
            details = nil
        }
    }
}

struct APIErrorDetails: Codable {
    let errors: [APIFieldError]
}

struct APIFieldError: Codable {
    let field: String
    let message: String
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

struct CurrentUserPayload: Codable {
    let user: User
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

struct PetInteractResponse: Codable {
    let xpAwarded: Int
    let alreadyInteracted: Bool
}

struct UnlockedOutfitsResponse: Codable {
    let outfits: [String]
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
