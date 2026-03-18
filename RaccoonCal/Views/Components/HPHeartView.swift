//
//  HPHeartView.swift
//  RaccoonCal
//
//  心形图标列表，展示宠物当前 HP（最多 5 颗）。
//  HP 值通过 max(0, min(hp, 5)) 限制在 [0, 5] 范围内。
//

import SwiftUI

// MARK: - HPHeartView

struct HPHeartView: View {

    /// 当前 HP 值（原始输入，内部会 clamp 到 [0, 5]）
    let hp: Int

    /// 心形图标尺寸
    var heartSize: CGFloat = 20

    // MARK: - Computed Properties

    /// 有效 HP，clamp 到 [0, 5]
    /// Property 3: HP 心形数量有界性：max(0, min(hp, 5))
    var clampedHP: Int {
        max(0, min(hp, 5))
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < clampedHP ? "heart.fill" : "heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: heartSize, height: heartSize)
                    .foregroundColor(index < clampedHP ? AppTheme.accent : AppTheme.textDisabled)
                    .animation(.easeInOut(duration: 0.2), value: clampedHP)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 满血
        HPHeartView(hp: 5)

        // 半血
        HPHeartView(hp: 3)

        // 空血
        HPHeartView(hp: 0)

        // 超出上界（clamp 到 5）
        HPHeartView(hp: 10)

        // 超出下界（clamp 到 0）
        HPHeartView(hp: -3)
    }
    .padding()
    .background(AppTheme.backgroundPrimary)
}
