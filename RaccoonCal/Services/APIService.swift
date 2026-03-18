//
//  APIService.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/13.
//

import Foundation
import UIKit

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
    private let decoder = JSONDecoder()
    
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
                throw decodeAPIError(from: data, statusCode: httpResponse.statusCode)
            }
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as APIServiceError {
            throw error
        } catch {
            throw APIServiceError.networkError(error.localizedDescription)
        }
    }

    private func decodeAPIError(from data: Data, statusCode: Int) -> APIServiceError {
        if let errorResponse = try? decoder.decode(APIResponse<String>.self, from: data) {
            let message = errorResponse.error?.details ?? errorResponse.error?.message
            if let message, !message.isEmpty {
                return .serverError(message)
            }
        }
        return .httpError(statusCode)
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
        let response: APIResponse<CurrentUserPayload> = try await request(
            endpoint: "/auth/me",
            method: .GET,
            responseType: APIResponse<CurrentUserPayload>.self
        )
        
        guard let data = response.data else {
            throw APIServiceError.noData
        }
        
        return data.user
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
    
    // MARK: - 食物识别与记录接口

    /// POST /api/food/recognize — 上传 UIImage 识别食物（JPEG 压缩 0.8）
    func recognizeFood(image: UIImage) async throws -> FoodRecognitionResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIServiceError.networkError("无法将图片转换为 JPEG 数据")
        }
        return try await recognizeFood(imageData: imageData)
    }

    /// POST /api/food/recognize — 上传图片识别食物（multipart/form-data）
    func recognizeFood(imageData: Data, mimeType: String = "image/jpeg") async throws -> FoodRecognitionResult {
        guard let url = URL(string: baseURL + "/food/recognize") else {
            throw APIServiceError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"food.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, response) = try await session.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        if httpResponse.statusCode >= 400 {
            throw decodeAPIError(from: data, statusCode: httpResponse.statusCode)
        }
        let decoded = try JSONDecoder().decode(APIResponse<FoodRecognitionResult>.self, from: data)
        guard let result = decoded.data else { throw APIServiceError.noData }
        return result
    }

    /// POST /api/food/records — 保存一条饮食记录
    func saveFoodRecord(_ input: SaveFoodRecordRequest) async throws -> FoodRecord {
        let body = try JSONEncoder().encode(input)
        let response: APIResponse<FoodRecord> = try await request(
            endpoint: "/food/records",
            method: .POST,
            body: body,
            responseType: APIResponse<FoodRecord>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// GET /api/food/records?date=YYYY-MM-DD — 获取饮食记录（可按日期过滤）
    func getFoodRecords(date: String? = nil) async throws -> DailyCalSummary {
        var endpoint = "/food/records"
        if let date = date {
            endpoint += "?date=\(date)"
        }
        let response: APIResponse<DailyCalSummary> = try await request(
            endpoint: endpoint,
            method: .GET,
            responseType: APIResponse<DailyCalSummary>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// DELETE /api/food/records/:id — 删除一条饮食记录
    func deleteFoodRecord(id: Int) async throws {
        let response: APIResponse<String?> = try await request(
            endpoint: "/food/records/\(id)",
            method: .DELETE,
            responseType: APIResponse<String?>.self
        )
        if !response.success {
            throw APIServiceError.serverError(response.error?.message ?? "删除失败")
        }
    }

    /// GET /api/food/stats?days=N — 获取 N 天营养统计
    func getFoodStats(days: Int = 7) async throws -> NutritionStats {
        let response: APIResponse<NutritionStats> = try await request(
            endpoint: "/food/stats?days=\(days)",
            method: .GET,
            responseType: APIResponse<NutritionStats>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    // MARK: - 游戏化接口

    /// GET /api/gamification/status — 获取游戏化状态（XP/等级/HP/Streak）
    func getGamificationStatus() async throws -> GamificationStatus {
        let response: APIResponse<GamificationStatus> = try await request(
            endpoint: "/gamification/status",
            method: .GET,
            responseType: APIResponse<GamificationStatus>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// GET /api/pet — 获取浣熊宠物状态（含心情计算）
    func getPetStatus() async throws -> PetStatus {
        let response: APIResponse<PetStatus> = try await request(
            endpoint: "/pet",
            method: .GET,
            responseType: APIResponse<PetStatus>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// POST /api/pet/interact — 与浣熊互动（每日一次，+XP）
    func interactWithPet() async throws -> PetInteractResponse {
        let response: APIResponse<PetInteractResponse> = try await request(
            endpoint: "/pet/interact",
            method: .POST,
            responseType: APIResponse<PetInteractResponse>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// GET /api/pet/level-history — 获取宠物升级历史（按 achievedAt 升序）
    func getPetLevelHistory() async throws -> [PetLevelEvent] {
        let response: APIResponse<[PetLevelEvent]> = try await request(
            endpoint: "/pet/level-history",
            method: .GET,
            responseType: APIResponse<[PetLevelEvent]>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// GET /api/pet/outfits — 获取已解锁装扮 key 列表
    func getUnlockedOutfits() async throws -> [String] {
        let response: APIResponse<UnlockedOutfitsResponse> = try await request(
            endpoint: "/pet/outfits",
            method: .GET,
            responseType: APIResponse<UnlockedOutfitsResponse>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data.outfits
    }

    /// PUT /api/pet/outfit — 更新浣熊装扮槽位
    func updatePetOutfit(_ outfit: PetOutfitRequest) async throws -> PetStatus {
        let body = try JSONEncoder().encode(outfit)
        let response: APIResponse<PetStatus> = try await request(
            endpoint: "/pet/outfit",
            method: .PUT,
            body: body,
            responseType: APIResponse<PetStatus>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    // MARK: - 任务与成就接口

    /// GET /api/tasks/daily?date=YYYY-MM-DD — 获取当日任务列表
    func getDailyTasks(date: String? = nil) async throws -> DailyTasksResponse {
        var endpoint = "/tasks/daily"
        if let date = date {
            endpoint += "?date=\(date)"
        }
        let response: APIResponse<DailyTasksResponse> = try await request(
            endpoint: endpoint,
            method: .GET,
            responseType: APIResponse<DailyTasksResponse>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// GET /api/achievements — 获取全部成就（含解锁状态）
    func getAchievements() async throws -> [Achievement] {
        let response: APIResponse<[Achievement]> = try await request(
            endpoint: "/achievements",
            method: .GET,
            responseType: APIResponse<[Achievement]>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    // MARK: - 联盟接口

    /// GET /api/league/current — 获取当前联盟信息（含 Top 10 排行榜）
    func getLeague() async throws -> LeagueInfo {
        let response: APIResponse<LeagueInfo> = try await request(
            endpoint: "/league/current",
            method: .GET,
            responseType: APIResponse<LeagueInfo>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// GET /api/league/settlement — 获取上次联盟结算结果
    func getLeagueSettlement() async throws -> LeagueSettlement? {
        let response: APIResponse<LeagueSettlement> = try await request(
            endpoint: "/league/settlement",
            method: .GET,
            responseType: APIResponse<LeagueSettlement>.self
        )
        return response.data
    }

    // MARK: - 个人资料接口

    /// GET /api/profile — 获取个人资料
    func getProfile() async throws -> UserProfile {
        let response: APIResponse<UserProfile> = try await request(
            endpoint: "/profile",
            method: .GET,
            responseType: APIResponse<UserProfile>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// PUT /api/profile — 更新个人资料（触发卡路里目标重算）
    func updateProfile(_ update: ProfileUpdateRequest) async throws -> UserProfile {
        let body = try JSONEncoder().encode(update)
        let response: APIResponse<UserProfile> = try await request(
            endpoint: "/profile",
            method: .PUT,
            body: body,
            responseType: APIResponse<UserProfile>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// POST /api/profile/weight — 记录体重
    func recordWeight(_ weight: Double) async throws -> WeightRecord {
        let body = try JSONEncoder().encode(["weight": weight])
        let response: APIResponse<WeightRecord> = try await request(
            endpoint: "/profile/weight",
            method: .POST,
            body: body,
            responseType: APIResponse<WeightRecord>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
    }

    /// GET /api/profile/weight-history — 获取体重历史
    func getWeightHistory() async throws -> [WeightRecord] {
        let response: APIResponse<[WeightRecord]> = try await request(
            endpoint: "/profile/weight-history",
            method: .GET,
            responseType: APIResponse<[WeightRecord]>.self
        )
        guard let data = response.data else { throw APIServiceError.noData }
        return data
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
            switch code {
            case 400:
                return "请求参数有误"
            case 401:
                return "登录已失效，请重新登录"
            case 403:
                return "没有权限执行此操作"
            case 404:
                return "请求的内容不存在"
            case 409:
                return "当前操作发生冲突，请稍后再试"
            case 503:
                return "服务暂时不可用，请稍后重试"
            default:
                return "HTTP错误: \(code)"
            }
        }
    }
}
