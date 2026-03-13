//
//  LoginView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct LoginView: View {
    @State private var identifier = ""
    @State private var password = ""
    @State private var agreedToTerms = false
    @State private var navigateToMain = false
    @State private var isLoggingIn = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @StateObject private var userManager = UserManager.shared
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                Image("RaccoonThinking")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                // 标题
                VStack(spacing: 10) {
                    Text("登录")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("欢迎回来")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 输入框
                VStack(spacing: 20) {
                    // 账号输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("账号")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("请输入用户名/邮箱/手机号", text: $identifier)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                    }
                    
                    // 密码输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        SecureField("请输入密码", text: $password)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
                
                // 同意条款
                HStack(spacing: 10) {
                    Button(action: {
                        agreedToTerms.toggle()
                    }) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreedToTerms ? AppTheme.primary : .gray)
                            .font(.title3)
                    }
                    
                    Text("我已阅读并同意《用户协议》和《隐私政策》")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
                
                // 登录按钮
                Button(action: {
                    Task {
                        await loginUser()
                    }
                }) {
                    HStack {
                        if isLoggingIn {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isLoggingIn ? "登录中..." : "登录")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? AppTheme.primary : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isLoggingIn)
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            // 隐藏的导航链接
            NavigationLink(destination: MainTabView().navigationBarBackButtonHidden(true), isActive: $navigateToMain) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("登录提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {
                if userManager.isLoggedIn {
                    navigateToMain = true
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        !identifier.isEmpty && 
        !password.isEmpty && 
        agreedToTerms
    }
    
    @MainActor
    private func loginUser() async {
        isLoggingIn = true
        
        do {
            try await userManager.login(identifier: identifier, password: password)
            
            alertMessage = "登录成功！欢迎回来"
            showAlert = true
            
        } catch let error as APIServiceError {
            alertMessage = error.localizedDescription
            showAlert = true
        } catch {
            alertMessage = "登录失败：\(error.localizedDescription)"
            showAlert = true
        }
        
        isLoggingIn = false
    }
}

#Preview {
    NavigationView {
        LoginView()
    }
}