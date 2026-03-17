//
//  APIService.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/13.
//

import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    
    // 可配置的baseURL，支持本地开发和生产环境
    private let baseURL: String = {
        #if DEBUG
        return "http://localhost:3000/api"
        #else
        return "https://your-production-api.com/api"
        #endif
    }()
    
    private let session: URLSession
    
    private init() {
        // 配置URLSession以支持HTTP连接
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
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
        let registerRequest = RegisterRequest(
            username: username,
            password: password,
            email: email,
            phone: nil
        )
        
        let body = try JSONEncoder().encode(registerRequest)
        let response: APIResponse<AuthResponse> = try await request(
            endpoint: "/auth/register",
            method: .POST,
            body: body,
            responseType: APIResponse<AuthResponse>.self
        )
        
        guard let data = response.data else {
            throw APIServiceError.noData
        }
        
        // 保存token
        UserDefaults.standard.set(data.token, forKey: "auth_token")
        
        return data
    }
    
    func login(identifier: String, password: String) async throws -> AuthResponse {
        let loginRequest = LoginRequest(identifier: identifier, password: password)
        let body = try JSONEncoder().encode(loginRequest)
        
        let response: APIResponse<AuthResponse> = try await request(
            endpoint: "/auth/login",
            method: .POST,
            body: body,
            responseType: APIResponse<AuthResponse>.self
        )
        
        guard let data = response.data else {
            throw APIServiceError.noData
        }
        
        // 保存token
        UserDefaults.standard.set(data.token, forKey: "auth_token")
        
        return data
    }
    
    func getCurrentUser() async throws -> User {
        let response: APIResponse<User> = try await request(
            endpoint: "/auth/me",
            method: .GET,
            responseType: APIResponse<User>.self
        )
        
        guard let data = response.data else {
            throw APIServiceError.noData
        }
        
        return data
    }
    
    // MARK: - 验证码接口
    func generateCaptcha() async throws -> CaptchaResponse {
        let response: APIResponse<CaptchaResponse> = try await request(
            endpoint: "/captcha/generate",
            method: .GET,
            responseType: APIResponse<CaptchaResponse>.self
        )
        
        guard let data = response.data else {
            throw APIServiceError.noData
        }
        
        return data
    }
    
    func verifyCaptcha(captchaId: String, captchaCode: String) async throws -> Bool {
        let verifyRequest = CaptchaVerifyRequest(captchaId: captchaId, captchaCode: captchaCode)
        let body = try JSONEncoder().encode(verifyRequest)
        
        let response: APIResponse<CaptchaVerifyResponse> = try await request(
            endpoint: "/captcha/verify",
            method: .POST,
            body: body,
            responseType: APIResponse<CaptchaVerifyResponse>.self
        )
        
        return response.data?.valid ?? false
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