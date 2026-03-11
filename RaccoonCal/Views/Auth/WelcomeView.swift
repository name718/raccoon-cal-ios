//
//  WelcomeView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showPrivacySheet = false
    @State private var navigateToLogin = false
    @State private var navigateToOnboarding = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo和标题
                    VStack(spacing: 20) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                        
                        Text("浣熊卡路里")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("让健康管理变得有趣")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 按钮区域
                    VStack(spacing: 20) {
                        // 已有账号？登录按钮
                        Button(action: {
                            showPrivacySheet = true
                        }) {
                            Text("已有账号？登录")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.primary)
                                .cornerRadius(12)
                        }
                        
                        // 第一次来 app - 马上开始按钮
                        Button(action: {
                            navigateToOnboarding = true
                        }) {
                            Text("第一次来？马上开始")
                                .font(.headline)
                                .foregroundColor(AppTheme.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.primary.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
                
                // 隐藏的导航链接
                NavigationLink(destination: LoginView(), isActive: $navigateToLogin) {
                    EmptyView()
                }
                .hidden()
                
                NavigationLink(destination: OnboardingView(), isActive: $navigateToOnboarding) {
                    EmptyView()
                }
                .hidden()
            }
            .sheet(isPresented: $showPrivacySheet) {
                PrivacyPolicySheet(navigateToLogin: $navigateToLogin)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    WelcomeView()
}