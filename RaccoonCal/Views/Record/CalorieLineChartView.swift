//
//  CalorieLineChartView.swift
//  RaccoonCal
//
//  Task 18.5 — 过去 7 天卡路里折线图（含目标虚线）
//

import SwiftUI
import Charts

/// 过去 7 天卡路里折线图，含每日目标虚线
struct CalorieLineChartView: View {

    /// 7 天数据点（来自 NutritionStats.dailyCalories）
    let dataPoints: [DailyCalories]

    /// 每日卡路里目标（默认 2000 kcal）
    var dailyTarget: Double = 2000

    // MARK: - Body

    var body: some View {
        if dataPoints.isEmpty {
            emptyView
        } else {
            chartView
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            // 目标虚线
            RuleMark(y: .value("目标", dailyTarget))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                .foregroundStyle(AppTheme.warning.opacity(0.8))
                .annotation(position: .top, alignment: .trailing) {
                    Text("目标 \(Int(dailyTarget))")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.warning)
                        .padding(.trailing, 4)
                }

            // 卡路里折线
            ForEach(dataPoints, id: \.date) { point in
                LineMark(
                    x: .value("日期", shortLabel(point.date)),
                    y: .value("卡路里", point.calories)
                )
                .foregroundStyle(AppTheme.primary)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("日期", shortLabel(point.date)),
                    y: .value("卡路里", point.calories)
                )
                .foregroundStyle(point.calories > dailyTarget ? AppTheme.warning : AppTheme.primary)
                .symbolSize(30)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.system(size: 11))
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

    // MARK: - Helpers

    /// "2024-01-15" → "1/15"
    private func shortLabel(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3 else { return dateStr }
        return "\(parts[1])/\(parts[2])"
    }
}

// MARK: - Preview

#Preview {
    let sampleData: [DailyCalories] = [
        DailyCalories(date: "2024-01-10", calories: 1800),
        DailyCalories(date: "2024-01-11", calories: 2200),
        DailyCalories(date: "2024-01-12", calories: 1950),
        DailyCalories(date: "2024-01-13", calories: 2400),
        DailyCalories(date: "2024-01-14", calories: 1700),
        DailyCalories(date: "2024-01-15", calories: 2100),
        DailyCalories(date: "2024-01-16", calories: 1850),
    ]
    return VStack {
        CalorieLineChartView(dataPoints: sampleData, dailyTarget: 2000)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .padding()
    }
    .background(Color(red: 255/255, green: 249/255, blue: 240/255))
}
