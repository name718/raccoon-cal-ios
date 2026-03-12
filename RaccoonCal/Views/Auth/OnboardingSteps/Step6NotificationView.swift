//
//  Step6NotificationView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/12.
//

import SwiftUI
import UserNotifications

struct Step6NotificationView: View {
    let onNext: () -> Void
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("RaccoonNotification")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 20) {
                Text("让我提醒你记录")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("开启通知后，我会在合适的时间提醒你记录饮食和运动")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("用餐时间提醒")
                            .font(.body)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("喝水提醒")
                            .font(.body)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(AppTheme.primary)
                        Text("运动提醒")
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
                    requestNotificationPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isRequesting ? "请求中..." : "开启通知")
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
    
    private func requestNotificationPermission() {
        isRequesting = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                isRequesting = false
                // 无论是否授权都继续下一步
                onNext()
            }
        }
    }
}

#Preview {
    Step6NotificationView(onNext: {})
}