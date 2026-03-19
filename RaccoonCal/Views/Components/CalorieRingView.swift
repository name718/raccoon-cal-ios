//
//  CalorieRingView.swift
//  RaccoonCal
//
//  环形进度条，展示当日卡路里摄入 vs 目标。
//  超标时（consumed > target）进度条颜色切换为 AppTheme.warning。
//

import SwiftUI

// MARK: - CalorieRingView

struct CalorieRingView: View {

    /// 已摄入卡路里
    let consumed: Double
    /// 每日卡路里目标
    let target: Double
    /// 环形线宽
    var lineWidth: CGFloat = 14
    /// 组件尺寸
    var size: CGFloat = 160

    // MARK: - Computed Properties

    /// 进度比例，clamp 到 [0, 1]
    /// Property 1: 对任意输入，progress ∈ [0.0, 1.0]
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(max(consumed / target, 0), 1)
    }

    /// 是否超标
    /// Property 2: consumed > target 时使用 warning 色
    var isOverTarget: Bool {
        consumed > target
    }

    /// 进度条颜色
    var ringColor: Color {
        isOverTarget ? AppTheme.warning : AppTheme.primary
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景轨道
            Circle()
                .stroke(AppTheme.primaryLight.opacity(0.4), lineWidth: lineWidth)

            // 进度弧
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)

            // 中心文字
            VStack(spacing: 2) {
                Text("\(Int(consumed))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isOverTarget ? AppTheme.warning : AppTheme.textPrimary)

                if target > 0 {
                    Text("/ \(Int(target)) kcal")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("目标未设置")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        // 正常状态（50% 进度）
        CalorieRingView(consumed: 1000, target: 2000)

        // 超标状态（警告色）
        CalorieRingView(consumed: 2500, target: 2000)

        // 边界：0 摄入
        CalorieRingView(consumed: 0, target: 2000)
    }
    .padding()
    .background(AppTheme.backgroundPrimary)
}
