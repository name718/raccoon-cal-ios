//
//  NutrientBarChartView.swift
//  RaccoonCal
//
//  Task 18.6 — 过去 7 天三大营养素柱状图（日均值）
//

import SwiftUI

/// 三大营养素数据点
struct MacroDataPoint: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let color: Color
}

/// 过去 7 天三大营养素日均值柱状图
struct NutrientBarChartView: View {

    /// 7 天蛋白质日均值（g）
    let avgProtein: Double

    /// 7 天脂肪日均值（g）
    let avgFat: Double

    /// 7 天碳水日均值（g）
    let avgCarbs: Double

    // MARK: - Computed

    private var dataPoints: [MacroDataPoint] {
        [
            MacroDataPoint(name: "蛋白质", value: avgProtein, color: AppTheme.info),
            MacroDataPoint(name: "脂肪",   value: avgFat,     color: AppTheme.warning),
            MacroDataPoint(name: "碳水",   value: avgCarbs,   color: AppTheme.secondary),
        ]
    }

    private var isEmpty: Bool {
        avgProtein == 0 && avgFat == 0 && avgCarbs == 0
    }

    // MARK: - Body

    var body: some View {
        if isEmpty {
            emptyView
        } else {
            chartView
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        GeometryReader { geometry in
            let maxValue = max(dataPoints.map(\.value).max() ?? 1, 1)

            HStack(alignment: .bottom, spacing: 20) {
                ForEach(dataPoints) { point in
                    VStack(spacing: 8) {
                        Text(String(format: "%.0fg", point.value))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(point.color.opacity(0.85))
                            .frame(
                                width: max(32, (geometry.size.width - 40) / 3 - 20),
                                height: max(12, (geometry.size.height - 44) * CGFloat(point.value / maxValue))
                            )

                        Text(point.name)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 160)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State

    private var emptyView: some View {
        Text("暂无数据")
            .font(.system(size: 13))
            .foregroundColor(AppTheme.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        NutrientBarChartView(avgProtein: 72.5, avgFat: 58.3, avgCarbs: 210.8)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .padding()
    }
    .background(Color(red: 255/255, green: 249/255, blue: 240/255))
}
