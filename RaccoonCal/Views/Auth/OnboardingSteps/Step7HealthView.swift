//
//  Step7HealthView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/12.
//

import SwiftUI

struct Step7HealthView: View {
    let onNext: () -> Void
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("RaccoonHealth")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 20) {
                Text("连接健康数据")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("授权后我可以帮你记录步数、消耗的卡路里，让数据更准确")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(AppTheme.primary)
                        Text("步数统计")
                            .font(.body)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("活动能量")
                            .font(.body)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("心率数据")
                            .font(.body)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("睡眠分析")
                            .font(.body)
                        Spacer()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
            }
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: {
                    requestHealthPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isRequesting ? "请求中..." : "授权健康数据")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .cornerRadius(12)
                }
                .disabled(isRequesting)
                
                Button(action: onNext) {
                    Text("跳过")
                        .font(.body)
                        .foregroundColor(AppTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    private func requestHealthPermission() {
        isRequesting = true
        
        // 模拟权限请求过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRequesting = false
            // 暂时跳过实际的HealthKit权限请求，直接继续
            onNext()
        }
    }
}

#Preview {
    Step7HealthView(onNext: {})
}