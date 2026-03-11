//
//  LaunchView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct LaunchView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.5
    
    var body: some View {
        if isActive {
            MainTabView()
        } else {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.8, blue: 0.6),
                        Color(red: 0.1, green: 0.6, blue: 0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo区域
                    VStack(spacing: 20) {
                        // 浣熊图标 (使用系统图标作为占位符)
                        Image(systemName: "pawprint.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                        
                        // 应用名称
                        Text("浣熊卡路里")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(logoOpacity)
                        
                        Text("RaccoonCal")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(logoOpacity)
                    }
                    
                    Spacer()
                    
                    // 底部标语
                    VStack(spacing: 10) {
                        Text("让健康管理变得有趣")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(logoOpacity)
                        
                        Text("拍照识别 • 虚拟宠物 • 社交互动")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(logoOpacity)
                    }
                    .padding(.bottom, 50)
                }
                .padding()
            }
            .onAppear {
                // 启动动画
                withAnimation(.easeInOut(duration: 1.0)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                
                // 2秒后跳转到主页面
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    LaunchView()
}