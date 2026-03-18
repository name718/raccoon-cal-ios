//
//  XPFloatLabel.swift
//  RaccoonCal
//
//  浮动 "+N XP" 动画标签，出现后向上漂移并淡出。
//  通过 GamificationManager 的 isXpFloatVisible / xpFloatAmount 驱动，
//  也可直接传入 amount + isVisible 独立使用。
//

import SwiftUI

// MARK: - XPFloatLabel

struct XPFloatLabel: View {

    /// 要显示的 XP 数量
    let amount: Int

    /// 是否可见（由外部控制，配合动画）
    let isVisible: Bool

    // MARK: - Body

    var body: some View {
        Text("+\(amount) XP")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppTheme.primary.opacity(0.15))
            )
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? -40 : 0)
            .animation(.easeOut(duration: 0.6), value: isVisible)
    }
}

// MARK: - View Modifier

/// 便捷修饰符：将浮动 XP 标签叠加在任意视图上，
/// 由 GamificationManager 的状态自动驱动。
struct XPFloatOverlay: ViewModifier {
    @ObservedObject var manager: GamificationManager

    func body(content: Content) -> some View {
        content.overlay(
            XPFloatLabel(
                amount: manager.xpFloatAmount,
                isVisible: manager.isXpFloatVisible
            )
        )
    }
}

extension View {
    /// 将浮动 XP 标签叠加在当前视图上，由 GamificationManager 驱动。
    func xpFloatOverlay(manager: GamificationManager = .shared) -> some View {
        modifier(XPFloatOverlay(manager: manager))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var visible = false

        var body: some View {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 40) {
                    // 独立使用示例
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.backgroundSecondary)
                            .frame(width: 200, height: 80)
                        Text("记录饮食")
                            .foregroundColor(AppTheme.textPrimary)
                        XPFloatLabel(amount: 50, isVisible: visible)
                    }

                    Button("触发 +50 XP") {
                        visible = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            visible = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                visible = false
                            }
                        }
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }

    return PreviewWrapper()
}
