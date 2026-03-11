//
//  Step3GoalView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct Step3GoalView: View {
    @Binding var goal: String
    @Binding var goalDuration: String
    @State private var showDuration = false
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 浣熊举着路牌
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            
            if !showDuration {
                // 选择目标
                VStack(spacing: 20) {
                    Text("你想让我陪你做什么")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        goalCard(title: "变瘦一点", subtitle: "健康减重", value: "减重")
                        goalCard(title: "变强壮", subtitle: "增肌塑形", value: "增肌")
                        goalCard(title: "开心就好", subtitle: "维持现状", value: "保持")
                        goalCard(title: "随便吃吃", subtitle: "佛系记录", value: "记录")
                    }
                    .padding(.horizontal, 30)
                }
            } else {
                // 选择周期
                VStack(spacing: 20) {
                    Text("想多久达成（不急不急）")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        durationButton(title: "1个月", value: "1个月")
                        durationButton(title: "3个月", value: "3个月")
                        durationButton(title: "半年", value: "半年")
                        durationButton(title: "随缘", value: "随缘")
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
    }
    
    private func goalCard(title: String, subtitle: String, value: String) -> some View {
        Button(action: {
            goal = value
            withAnimation {
                showDuration = true
            }
        }) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if goal == value {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.primary)
                        .font(.title3)
                }
            }
            .padding()
            .background(goal == value ? AppTheme.primaryLight.opacity(0.3) : Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    private func durationButton(title: String, value: String) -> some View {
        Button(action: {
            goalDuration = value
            onNext()
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(goalDuration == value ? .white : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(goalDuration == value ? AppTheme.primary : Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
}
