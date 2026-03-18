//
//  LeagueSettlementSheet.swift
//  RaccoonCal
//
//  Task 20.10 — 联盟结算结果弹窗（晋升/降级提示）
//

import SwiftUI

// MARK: - LeagueSettlementSheet

struct LeagueSettlementSheet: View {

    let settlement: LeagueSettlement
    var onDismiss: () -> Void

    @State private var appeared = false

    // MARK: - Computed helpers

    private var isPromoted: Bool { settlement.promoted == true }
    private var isDemoted: Bool  { settlement.demoted  == true }

    private var raccoonImage: String {
        if isPromoted { return "RaccoonExcited" }
        if isDemoted  { return "RaccoonThinking" }
        return "RaccoonHappy"
    }

    private var resultTitle: String {
        if isPromoted { return "恭喜晋级！" }
        if isDemoted  { return "本周降级" }
        return "保级成功！"
    }

    private var resultSubtitle: String {
        if isPromoted { return "你已晋升到更高联盟，继续加油！" }
        if isDemoted  { return "下周继续努力，重新冲击更高联盟！" }
        return "你成功保住了联盟席位，继续保持！"
    }

    private var accentColor: Color {
        if isPromoted { return AppTheme.secondary }
        if isDemoted  { return AppTheme.accent }
        return AppTheme.primary
    }

    private var tierName: String {
        switch settlement.newTier.lowercased() {
        case "bronze":   return "🥉 青铜"
        case "silver":   return "🥈 白银"
        case "gold":     return "🥇 黄金"
        case "platinum": return "💎 铂金"
        case "diamond":  return "💠 钻石"
        default:         return settlement.newTier
        }
    }

    private var tierColor: Color {
        switch settlement.newTier.lowercased() {
        case "bronze":   return Color(red: 0.8, green: 0.5, blue: 0.2)
        case "silver":   return Color(red: 0.6, green: 0.6, blue: 0.65)
        case "gold":     return AppTheme.primary
        case "platinum": return Color(red: 0.4, green: 0.7, blue: 0.85)
        case "diamond":  return Color(red: 0.3, green: 0.6, blue: 1.0)
        default:         return AppTheme.textSecondary
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.gradientBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle bar
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Raccoon image
                Image(raccoonImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: appeared)
                    .padding(.bottom, 16)

                // Result badge
                Text(isPromoted ? "⬆️" : isDemoted ? "⬇️" : "✅")
                    .font(.system(size: 36))
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

                // Title
                Text(resultTitle)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(accentColor)
                    .padding(.top, 8)
                    .opacity(appeared ? 1.0 : 0.0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

                // Subtitle
                Text(resultSubtitle)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 6)
                    .opacity(appeared ? 1.0 : 0.0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

                // Stats card
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        statCell(
                            value: tierName,
                            label: "当前联盟",
                            valueColor: tierColor
                        )
                        Divider().frame(height: 44)
                        statCell(
                            value: "#\(settlement.finalRank)",
                            label: "本周排名",
                            valueColor: AppTheme.textPrimary
                        )
                    }
                }
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .opacity(appeared ? 1.0 : 0.0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.45).delay(0.25), value: appeared)

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Text("知道了")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(accentColor)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .opacity(appeared ? 1.0 : 0.0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
            }
        }
        .onAppear {
            appeared = true
        }
    }

    // MARK: - Helpers

    private func statCell(value: String, label: String, valueColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

#Preview {
    LeagueSettlementSheet(
        settlement: LeagueSettlement(
            promoted: true,
            demoted: nil,
            newTier: "silver",
            finalRank: 3
        ),
        onDismiss: {}
    )
}
