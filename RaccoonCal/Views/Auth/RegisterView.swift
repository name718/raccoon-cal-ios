//
//  RegisterView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var navigateToMain = false
    @State private var isRegistering = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
                    print("注册按钮被点击")
                    print("表单验证状态: \(isFormValid)")
                    print("邮箱: \(email)")
                    print("密码长度: \(password.count)")
                    print("密码一致: \(password == confirmPassword)")
                    print("同意条款: \(agreedToTerms)")
                    registerUser()
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
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        password.count >= 6 &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        agreedToTerms
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func registerUser() {
        // 在注册前再次验证邮箱格式
        if !isValidEmail(email) {
            alertMessage = "请输入有效的邮箱地址"
            showAlert = true
            return
        }
        
        isRegistering = true
        
        // 模拟注册过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isRegistering = false
            
            // 模拟注册成功
            alertMessage = "注册成功！欢迎加入浣熊卡路里"
            showAlert = true
            
            // 延迟跳转到主页面
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                navigateToMain = true
            }
        }
    }
}

#Preview {
    NavigationView {
        RegisterView()
    }
}