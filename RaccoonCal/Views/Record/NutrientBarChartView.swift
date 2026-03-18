//
//  NutrientBarChartView.swift
//  RaccoonCal
//
//  Task 18.6 — 过去 7 天三大营养素柱状图（日均值）
//

import SwiftUI
import Charts

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
        Chart(dataPoints) { point in
            BarMark(
                x: .value("营养素", point.name),
                y: .value("克数", point.value)
            )
            .foregroundStyle(point.color.opacity(0.85))
            .cornerRadius(6)
            .annotation(position: .top, alignment: .center) {
                Text(String(format: "%.0fg", point.value))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.15))
            }
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
