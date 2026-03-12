//
//  Step5CompleteView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct Step5CompleteView: View {
    let nickname: String
    let onComplete: () -> Void
    @State private var isGenerating = true
    @State private var progress: CGFloat = 0
    @State private var loadingText = "正在分析你的信息"
    
    let loadingSteps = [
        "正在分析你的信息",
        "正在生成专属计划",
        "正在准备你的健康伙伴",
        "马上就好"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 浣熊
            Image(isGenerating ? "RaccoonLoading" : "RaccoonSuccess")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(isGenerating ? 360 : 0))
                .animation(
                    isGenerating ? Animation.linear(duration: 2).repeatForever(autoreverses: false) : .default,
                    value: isGenerating
                )
            
            if isGenerating {
                VStack(spacing: 20) {
                    Text(loadingText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    // 进度条
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.primary)
                            .frame(width: progress * 280, height: 8)
                    }
                    .frame(width: 280)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 15) {
                    Text("准备完成")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primary)
                    
                    Text("让我们开始健康之旅吧")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .onAppear {
            startGenerating()
        }
    }
    
    private func startGenerating() {
        // 模拟生成过程
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.01
                
                // 更新文字
                let stepIndex = Int(progress * 4)
                if stepIndex < loadingSteps.count && stepIndex != currentStep {
                    currentStep = stepIndex
                    withAnimation {
                        loadingText = loadingSteps[stepIndex]
                    }
                }
            } else {
                timer.invalidate()
                withAnimation {
                    isGenerating = false
                }
                // 延迟0.5秒后跳转
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}
