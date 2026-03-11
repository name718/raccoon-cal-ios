//
//  Step1NicknameView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct Step1NicknameView: View {
    @Binding var nickname: String
    @State private var showConfirmation = false
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 浣熊挥手
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            if !showConfirmation {
                // 第一步：输入昵称
                VStack(spacing: 20) {
                    Text("嗨！我是小R，你的专属健康伙伴")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("你叫什么名字")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    TextField("输入你的昵称", text: $nickname)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(AppTheme.primaryLight.opacity(0.3))
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        if !nickname.isEmpty {
                            withAnimation {
                                showConfirmation = true
                            }
                        }
                    }) {
                        Text("下一步")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(nickname.isEmpty ? Color.gray : AppTheme.primary)
                            .cornerRadius(12)
                    }
                    .disabled(nickname.isEmpty)
                    .padding(.horizontal, 40)
                }
            } else {
                // 第二步：确认昵称
                VStack(spacing: 20) {
                    Text("以后我就叫你")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(nickname)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primary)
                    
                    Text("可以吗")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            withAnimation {
                                showConfirmation = false
                            }
                        }) {
                            Text("改一下")
                                .font(.body)
                                .foregroundColor(AppTheme.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.primary.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        Button(action: onNext) {
                            Text("超棒！")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.primary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
    }
}
