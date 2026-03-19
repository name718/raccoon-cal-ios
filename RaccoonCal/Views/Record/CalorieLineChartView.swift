//
//  CalorieLineChartView.swift
//  RaccoonCal
//
//  Task 18.5 — 过去 7 天卡路里折线图（含目标虚线）
//

import SwiftUI

/// 过去 7 天卡路里折线图，含每日目标虚线
struct CalorieLineChartView: View {

    /// 7 天数据点（来自 NutritionStats.dailyCalories）
    let dataPoints: [DailyCalories]

    /// 每日卡路里目标（<= 0 代表未设置）
    var dailyTarget: Double = 0

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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if dailyTarget > 0 {
                    Text("目标 \(Int(dailyTarget)) kcal")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.warning)
                } else {
                    Text("目标未设置")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)

            GeometryReader { geometry in
                let layout = chartLayout(
                    size: geometry.size,
                    values: dailyTarget > 0
                        ? dataPoints.map(\.calories) + [dailyTarget]
                        : dataPoints.map(\.calories)
                )

                ZStack {
                    // Y 轴辅助线
                    ForEach(Array(layout.gridValues.enumerated()), id: \.offset) { _, value in
                        let y = yPosition(for: value, in: layout)
                        Path { path in
                            path.move(to: CGPoint(x: layout.leftInset, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width - layout.rightInset, y: y))
                        }
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    }

                    // 目标虚线
                    if dailyTarget > 0 {
                        Path { path in
                            let y = yPosition(for: dailyTarget, in: layout)
                            path.move(to: CGPoint(x: layout.leftInset, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width - layout.rightInset, y: y))
                        }
                        .stroke(
                            AppTheme.warning.opacity(0.8),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                        )
                    }

                    // 折线
                    Path { path in
                        for (index, point) in dataPoints.enumerated() {
                            let x = xPosition(
                                for: index,
                                count: dataPoints.count,
                                in: layout,
                                width: geometry.size.width
                            )
                            let y = yPosition(for: point.calories, in: layout)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))

                    // 数据点
                    ForEach(Array(dataPoints.enumerated()), id: \.element.date) { index, point in
                        let x = xPosition(
                            for: index,
                            count: dataPoints.count,
                            in: layout,
                            width: geometry.size.width
                        )
                        let y = yPosition(for: point.calories, in: layout)

                        Circle()
                            .fill(dailyTarget > 0 && point.calories > dailyTarget ? AppTheme.warning : AppTheme.primary)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)

                        Text(shortLabel(point.date))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                            .position(x: x, y: geometry.size.height - 10)
                    }
                }
            }
            .frame(height: 160)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
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

    private func chartLayout(size: CGSize, values: [Double]) -> LineChartLayout {
        let leftInset: CGFloat = 4
        let rightInset: CGFloat = 4
        let topInset: CGFloat = 12
        let bottomInset: CGFloat = 24

        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let padding = max((maxValue - minValue) * 0.15, 100)
        let lowerBound = max(0, minValue - padding)
        let upperBound = maxValue + padding
        let gridValues = stride(from: lowerBound, through: upperBound, by: max((upperBound - lowerBound) / 3, 1)).map { $0 }

        return LineChartLayout(
            leftInset: leftInset,
            rightInset: rightInset,
            topInset: topInset,
            bottomInset: bottomInset,
            minValue: lowerBound,
            maxValue: max(upperBound, lowerBound + 1),
            gridValues: gridValues
        )
    }

    private func xPosition(
        for index: Int,
        count: Int,
        in layout: LineChartLayout,
        width: CGFloat
    ) -> CGFloat {
        guard count > 1 else { return layout.leftInset }
        let usableWidth = width - layout.leftInset - layout.rightInset
        let step = usableWidth / CGFloat(count - 1)
        return layout.leftInset + CGFloat(index) * step
    }

    private func yPosition(for value: Double, in layout: LineChartLayout) -> CGFloat {
        let chartHeight = max(1, 160 - layout.topInset - layout.bottomInset)
        let progress = (value - layout.minValue) / (layout.maxValue - layout.minValue)
        return layout.topInset + chartHeight * CGFloat(1 - progress)
    }
}

private struct LineChartLayout {
    let leftInset: CGFloat
    let rightInset: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat
    let minValue: Double
    let maxValue: Double
    let gridValues: [Double]
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
