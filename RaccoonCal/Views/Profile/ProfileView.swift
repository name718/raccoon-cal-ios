//
//  ProfileView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var showLogoutAlert = false
    @State private var showAPITestAlert = false
    @State private var apiTestMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // 用户头像
                Image("RaccoonHappy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppTheme.primary, lineWidth: 3)
                    )
                
                // 用户信息
                VStack(spacing: 8) {
                    if let user = userManager.currentUser {
                        Text(user.username)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let email = user.email {
                            Text(email)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            if user.emailVerified == true {
                                Label("邮箱已验证", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Label("邮箱未验证", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    } else {
                        Text("加载中...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 功能列表
                VStack(spacing: 15) {
                    profileMenuItem(
                        icon: "network",
                        title: "测试API连接",
                        action: {
                            Task {
                                await testAPIConnection()
                            }
                        }
                    )
                    
                    profileMenuItem(
                        icon: "person.circle",
                        title: "个人信息",
                        action: {
                            // TODO: 跳转到个人信息编辑页面
                        }
                    )
                    
                    profileMenuItem(
                        icon: "bell",
                        title: "通知设置",
                        action: {
                            // TODO: 跳转到通知设置页面
                        }
                    )
                    
                    profileMenuItem(
                        icon: "heart.text.square",
                        title: "健康数据",
                        action: {
                            // TODO: 跳转到健康数据页面
                        }
                    )
                    
                    profileMenuItem(
                        icon: "questionmark.circle",
                        title: "帮助与反馈",
                        action: {
                            // TODO: 跳转到帮助页面
                        }
                    )
                    
                    profileMenuItem(
                        icon: "info.circle",
                        title: "关于我们",
                        action: {
                            // TODO: 跳转到关于页面
                        }
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 登出按钮
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("退出登录")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("确认退出", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                userManager.logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
        .alert("API测试结果", isPresented: $showAPITestAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(apiTestMessage)
        }
        .onAppear {
            // 加载用户信息
            if userManager.currentUser == nil {
                Task {
                    await userManager.loadCurrentUser()
                }
            }
        }
    }
    
    private func profileMenuItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    @MainActor
    private func testAPIConnection() async {
        do {
            let captcha = try await APIService.shared.generateCaptcha()
            apiTestMessage = "API连接成功！\n验证码ID: \(captcha.captchaId.prefix(8))..."
        } catch {
            apiTestMessage = "API连接失败：\(error.localizedDescription)"
        }
        showAPITestAlert = true
    }
}

#Preview {
    ProfileView()
}