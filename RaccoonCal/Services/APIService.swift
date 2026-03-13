//
//  APIService.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/13.
//

import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:3000/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - 通用请求方法
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证token
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIServiceError.invalidResponse
            }
            
            // 处理HTTP状态码
            if httpResponse.statusCode >= 400 {
                // 尝试解析错误响应
                if let errorResponse = try? JSONDecoder().decode(APIResponse<String>.self, from: data) {
                    throw APIServiceError.serverError(errorResponse.error?.message ?? "未知错误")
                } else {
                    throw APIServiceError.httpError(httpResponse.statusCode)
                }
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
            
        } catch let error as APIServiceError {
            throw error
        } catch {
            throw APIServiceError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - 认证接口
    func register(username: String, password: String, email: String?) async throws -> AuthResponse {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        // 模拟注册成功
        let user = User(
            id: 1,
            username: username,
            email: email,
            phone: nil,
            emailVerified: false,
            phoneVerified: false,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let token = "mock_token_\(UUID().uuidString)"
        
        // 保存token
        UserDefaults.standard.set(token, forKey: "auth_token")
        
        return AuthResponse(user: user, token: token)
    }
    
    func login(identifier: String, password: String) async throws -> AuthResponse {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        // 简单的模拟验证
        if password.count < 6 {
            throw APIServiceError.serverError("密码错误")
        }
        
        // 模拟登录成功
        let user = User(
            id: 1,
            username: identifier,
            email: identifier.contains("@") ? identifier : nil,
            phone: nil,
            emailVerified: false,
            phoneVerified: false,
            createdAt: nil
        )
        
        let token = "mock_token_\(UUID().uuidString)"
        
        // 保存token
        UserDefaults.standard.set(token, forKey: "auth_token")
        
        return AuthResponse(user: user, token: token)
    }
    
    func getCurrentUser() async throws -> User {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 模拟返回用户信息
        return User(
            id: 1,
            username: "testuser",
            email: "test@example.com",
            phone: nil,
            emailVerified: false,
            phoneVerified: false,
            createdAt: nil
        )
    }
    
    // MARK: - 验证码接口
    func generateCaptcha() async throws -> CaptchaResponse {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 模拟验证码
        return CaptchaResponse(
            captchaId: UUID().uuidString,
            captchaImage: "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTIwIiBoZWlnaHQ9IjQwIj48dGV4dCB4PSI2MCIgeT0iMjUiIGZvbnQtc2l6ZT0iMjAiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkFCQ0Q8L3RleHQ+PC9zdmc+"
        )
    }
    
    func verifyCaptcha(captchaId: String, captchaCode: String) async throws -> Bool {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 模拟验证成功
        return captchaCode.uppercased() == "ABCD"
    }
    
    // MARK: - 登出
    func logout() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - 检查登录状态
    var isLoggedIn: Bool {
        return UserDefaults.standard.string(forKey: "auth_token") != nil
    }
}

// MARK: - HTTP方法枚举
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - API错误类型
enum APIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case networkError(String)
    case serverError(String)
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .noData:
            return "没有数据"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        }
    }
}