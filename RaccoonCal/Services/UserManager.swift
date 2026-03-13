//
//  UserManager.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/13.
//

import Foundation
import SwiftUI

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    private let apiService = APIService.shared
    
    private init() {
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        isLoggedIn = apiService.isLoggedIn
        
        if isLoggedIn {
            Task {
                await loadCurrentUser()
            }
        }
    }
    
    @MainActor
    func loadCurrentUser() async {
        do {
            currentUser = try await apiService.getCurrentUser()
        } catch {
            print("加载用户信息失败: \(error)")
            // 如果获取用户信息失败，可能token已过期，清除登录状态
            logout()
        }
    }
    
    @MainActor
    func register(username: String, password: String, email: String?) async throws {
        let authResponse = try await apiService.register(username: username, password: password, email: email)
        currentUser = authResponse.user
        isLoggedIn = true
    }
    
    @MainActor
    func login(identifier: String, password: String) async throws {
        let authResponse = try await apiService.login(identifier: identifier, password: password)
        currentUser = authResponse.user
        isLoggedIn = true
    }
    
    func logout() {
        apiService.logout()
        currentUser = nil
        isLoggedIn = false
    }
}