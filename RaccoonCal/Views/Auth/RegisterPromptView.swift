//
//  RegisterPromptView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct RegisterPromptView: View {
    @Binding var navigateToMain: Bool
    @Binding var navigateToRegister: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            // 标题
            VStack(spacing: 15) {
                Text("太棒了！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("我们已经了解了你的基本信息")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("注册账号可以保存这些信息，并在多设备间同步")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // 按钮区域
            VStack(spacing: 15) {
                // 注册按钮
                Button(action: {
                    navigateToRegister = true
                }) {
                    Text("注册账号")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary)
                        .cornerRadius(12)
                }
                
                // 跳过按钮
                Button(action: {
                    navigateToMain = true
                }) {
                    Text("暂时跳过")
                        .font(.body)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}

#Preview {
    RegisterPromptView(navigateToMain: .constant(false), navigateToRegister: .constant(false))
}
