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
    @Published var isRestoringSession: Bool = true
    
    private let apiService = APIService.shared
    
    private init() {
        NotificationCenter.default.addObserver(
            forName: APIService.authenticationExpiredNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAuthenticationExpired()
            }
        }

        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        isRestoringSession = true
        currentUser = nil
        isLoggedIn = false

        if apiService.isLoggedIn {
            Task {
                await loadCurrentUser()
            }
        } else {
            isRestoringSession = false
        }
    }
    
    @MainActor
    func loadCurrentUser() async {
        do {
            currentUser = try await apiService.getCurrentUser()
            isLoggedIn = true
        } catch {
            print("加载用户信息失败: \(error)")
            logout()
        }

        isRestoringSession = false
    }
    
    @MainActor
    func register(username: String, password: String, email: String?) async throws {
        let authResponse = try await apiService.register(username: username, password: password, email: email)

        do {
            let profileRequest = buildInitialProfileRequest(for: authResponse.user)
            _ = try await apiService.updateProfile(profileRequest)

            currentUser = authResponse.user
            isLoggedIn = true
            OnboardingData.clear()
        } catch {
            logout()
            throw error
        }
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
        isRestoringSession = false
    }

    private func buildInitialProfileRequest(for user: User) -> ProfileUpdateRequest {
        if let onboardingData = OnboardingData.load() {
            return onboardingData.toProfileUpdateRequest(
                fallbackNickname: user.username
            )
        }

        return ProfileUpdateRequest(
            nickname: user.username,
            gender: "other",
            height: 170,
            weight: 60,
            age: 25,
            goal: "maintain",
            activityLevel: "sedentary"
        )
    }

    @MainActor
    private func handleAuthenticationExpired() {
        currentUser = nil
        isLoggedIn = false
        isRestoringSession = false
    }
}
