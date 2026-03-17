//
//  RegisterView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct RegisterView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var captchaCode = ""
    @State private var agreedToTerms = false
    @State private var navigateToMain = false
    @State private var isRegistering = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCaptcha = false
    @State private var captchaVerified = false
    
    @StateObject private var userManager = UserManager.shared
    @StateObject private var captchaManager = CaptchaManager()
    
    var body: some View {
        ZStack {
            VStack(spacing: 25) {
                Spacer()
                
                // Logo
                Image("RaccoonHappy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                // 标题
                VStack(spacing: 10) {
                    Text("注册账号")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("保存你的健康数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 输入框
                VStack(spacing: 15) {
                    // 用户名输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("用户名")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("请输入用户名（3-20个字符）", text: $username)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(usernameValidationColor, lineWidth: 1)
                            )
                        
                        if !username.isEmpty && !isValidUsername(username) {
                            Text("用户名需要3-20个字符，只能包含字母和数字")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 邮箱输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("邮箱")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("请输入邮箱", text: $email)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(emailValidationColor, lineWidth: 1)
                            )
                        
                        if !email.isEmpty && !isValidEmail(email) {
                            Text("请输入有效的邮箱地址")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 密码输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        SecureField("请输入密码（至少6位）", text: $password)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(passwordValidationColor, lineWidth: 1)
                            )
                        
                        if !password.isEmpty && password.count < 6 {
                            Text("密码至少需要6位")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 确认密码输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("确认密码")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        SecureField("请再次输入密码", text: $confirmPassword)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(confirmPasswordValidationColor, lineWidth: 1)
                            )
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("两次输入的密码不一致")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 验证码（如果需要）
                    if showCaptcha {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("验证码")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            CaptchaView(captchaCode: $captchaCode) {
                                captchaVerified = true
                                showCaptcha = false
                            }
                        }
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
                
                // 注册按钮
                Button(action: {
                    Task {
                        await handleRegister()
                    }
                }) {
                    HStack {
                        if isRegistering {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isRegistering ? "注册中..." : "注册")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? AppTheme.primary : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isRegistering)
                .padding(.horizontal, 30)
                
                // 冷却时间提示
                if captchaManager.needsCaptcha && !captchaVerified {
                    Text("请等待 \(captchaManager.remainingCooldownTime) 秒后重试")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // 登录链接
                HStack {
                    Text("已有账号？")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button("立即登录") {
                        // 返回到登录页面
                        // 这里可以通过导航或者回调实现
                    }
                    .font(.body)
                    .foregroundColor(AppTheme.primary)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            
            // 隐藏的导航链接
            NavigationLink(destination: MainTabView().navigationBarBackButtonHidden(true), isActive: $navigateToMain) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("注册提示", isPresented: $showAlert) {
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
        let basicValid = isValidUsername(username) &&
                        isValidEmail(email) &&
                        password.count >= 6 &&
                        password == confirmPassword &&
                        agreedToTerms
        
        // 如果需要验证码，必须验证通过
        if showCaptcha {
            return basicValid && captchaVerified
        }
        
        return basicValid
    }
    
    private var usernameValidationColor: Color {
        if username.isEmpty {
            return Color.clear
        }
        return isValidUsername(username) ? AppTheme.primary : Color.red
    }
    
    private var emailValidationColor: Color {
        if email.isEmpty {
            return Color.clear
        }
        return isValidEmail(email) ? AppTheme.primary : Color.red
    }
    
    private var passwordValidationColor: Color {
        if password.isEmpty {
            return Color.clear
        }
        return password.count >= 6 ? AppTheme.primary : Color.red
    }
    
    private var confirmPasswordValidationColor: Color {
        if confirmPassword.isEmpty {
            return Color.clear
        }
        return password == confirmPassword ? AppTheme.primary : Color.red
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9]{3,20}$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    @MainActor
    private func handleRegister() async {
        // 检查是否需要验证码
        if captchaManager.needsCaptcha && !captchaVerified {
            showCaptcha = true
            return
        }
        
        await registerUser()
    }
    
    @MainActor
    private func registerUser() async {
        isRegistering = true
        
        do {
            try await userManager.register(
                username: username,
                password: password,
                email: email.isEmpty ? nil : email
            )
            
            // 记录请求时间
            captchaManager.recordRequest()
            
            alertMessage = "注册成功！欢迎加入浣熊卡路里"
            showAlert = true
            
        } catch let error as APIServiceError {
            alertMessage = error.localizedDescription
            showAlert = true
        } catch {
            alertMessage = "注册失败：\(error.localizedDescription)"
            showAlert = true
        }
        
        isRegistering = false
    }
}

#Preview {
    NavigationView {
        RegisterView()
    }
}