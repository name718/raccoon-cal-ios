//
//  Step8CameraView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/12.
//

import SwiftUI

struct Step8CameraView: View {
    let onNext: () -> Void
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("RaccoonCamera")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 20) {
                Text("拍照记录美食")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("开启相机权限后，你就可以拍照记录每一餐了")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("拍摄食物照片")
                            .font(.body)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundColor(AppTheme.primary)
                        Text("记录饮食瞬间")
                            .font(.body)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(AppTheme.primary)
                        Text("AI智能识别")
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
                    requestCameraPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isRequesting ? "请求中..." : "开启相机")
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
                    Text("稍后设置")
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
    
    private func requestCameraPermission() {
        isRequesting = true
        
        // 模拟相机权限请求过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRequesting = false
            // 暂时跳过实际的相机权限请求，直接继续
            onNext()
        }
    }
}

#Preview {
    Step8CameraView(onNext: {})
}