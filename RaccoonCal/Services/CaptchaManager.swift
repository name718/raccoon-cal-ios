//
//  CaptchaManager.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/13.
//

import Foundation
import SwiftUI

class CaptchaManager: ObservableObject {
    @Published var captchaImage: String?
    @Published var captchaId: String?
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    private var lastRequestTime: Date?
    private let cooldownPeriod: TimeInterval = 60 // 60秒冷却时间
    
    // 检查是否需要验证码（60秒内有过请求）
    var needsCaptcha: Bool {
        guard let lastTime = lastRequestTime else { return false }
        return Date().timeIntervalSince(lastTime) < cooldownPeriod
    }
    
    // 获取剩余冷却时间
    var remainingCooldownTime: Int {
        guard let lastTime = lastRequestTime else { return 0 }
        let elapsed = Date().timeIntervalSince(lastTime)
        return max(0, Int(cooldownPeriod - elapsed))
    }
    
    // 记录请求时间
    func recordRequest() {
        lastRequestTime = Date()
    }
    
    // 生成验证码
    @MainActor
    func generateCaptcha() async {
        isLoading = true
        
        do {
            let captcha = try await apiService.generateCaptcha()
            captchaId = captcha.captchaId
            captchaImage = captcha.captchaImage
        } catch {
            print("生成验证码失败: \(error)")
        }
        
        isLoading = false
    }
    
    // 验证验证码
    func verifyCaptcha(code: String) async throws -> Bool {
        guard let captchaId = captchaId else {
            throw CaptchaError.noCaptchaId
        }
        
        return try await apiService.verifyCaptcha(captchaId: captchaId, captchaCode: code)
    }
    
    // 清除验证码
    func clearCaptcha() {
        captchaId = nil
        captchaImage = nil
    }
}

enum CaptchaError: LocalizedError {
    case noCaptchaId
    
    var errorDescription: String? {
        switch self {
        case .noCaptchaId:
            return "验证码ID不存在"
        }
    }
}