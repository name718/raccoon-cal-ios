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
    
    var body: some View {
        ZStack {
            VStack(spacing: 25) {
                Spacer()
                
                // Logo
                Image("Logo")
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
                    // TODO: 调用注册接口
                    navigateToMain = true
                }) {
                    Text("注册")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? AppTheme.primary : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid)
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
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty && 
        password == confirmPassword && 
        agreedToTerms
    }
}

#Preview {
    NavigationView {
        RegisterView()
    }
}
