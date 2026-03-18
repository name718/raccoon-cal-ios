//
//  WeightLineChartView.swift
//  RaccoonCal
//
//  Task 20.8 — 体重历史折线图（最近 30 天）
//

import SwiftUI

/// 最近 30 天体重折线图
struct WeightLineChartView: View {

    /// 全部体重记录（由 ProfileView 传入，内部取最近 30 条）
    let records: [WeightRecord]

    // MARK: - Computed

    /// 最近 30 天数据，按日期升序
    private var last30: [WeightRecord] {
        let sorted = records.sorted { $0.recordedAt < $1.recordedAt }
        return Array(sorted.suffix(30))
    }

    private var minWeight: Double { last30.map(\.weight).min() ?? 0 }
    private var maxWeight: Double { last30.map(\.weight).max() ?? 0 }

    // MARK: - Body

    var body: some View {
        if last30.isEmpty {
            emptyView
        } else {
            chartView
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Min / Max 标签行
            HStack {
                Label(String(format: "最低 %.1f kg", minWeight), systemImage: "arrow.down")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.info)
                Spacer()
                Label(String(format: "最高 %.1f kg", maxWeight), systemImage: "arrow.up")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.accent)
            }
            .padding(.horizontal, 16)

            GeometryReader { geometry in
                let layout = chartLayout(size: geometry.size)

                ZStack {
                    ForEach(Array(layout.gridValues.enumerated()), id: \.offset) { _, value in
                        let y = yPosition(for: value, in: layout)
                        Path { path in
                            path.move(to: CGPoint(x: layout.leftInset, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width - layout.rightInset, y: y))
                        }
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    }

                    Path { path in
                        for (index, record) in last30.enumerated() {
                            let x = xPosition(for: index, count: last30.count, in: layout, width: geometry.size.width)
                            let y = yPosition(for: record.weight, in: layout)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))

                    ForEach(Array(last30.enumerated()), id: \.element.id) { index, record in
                        let x = xPosition(for: index, count: last30.count, in: layout, width: geometry.size.width)
                        let y = yPosition(for: record.weight, in: layout)

                        Circle()
                            .fill(pointColor(for: record.weight))
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)

                        if shouldShowLabel(for: index, count: last30.count) {
                            Text(shortLabel(record.recordedAt))
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.textSecondary)
                                .position(x: x, y: geometry.size.height - 10)
                        }
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
        Text("暂无体重记录")
            .font(.system(size: 13))
            .foregroundColor(AppTheme.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
    }

    // MARK: - Helpers

    /// Y 轴留出上下 1 kg 的边距，避免数据点贴边
    private var yDomain: ClosedRange<Double> {
        let padding = max((maxWeight - minWeight) * 0.2, 1.0)
        return (minWeight - padding)...(maxWeight + padding)
    }

    /// "2024-01-15T08:00:00.000Z" → "1/15"
    private func shortLabel(_ dateStr: String) -> String {
        let prefix = String(dateStr.prefix(10)) // "2024-01-15"
        let parts = prefix.split(separator: "-")
        guard parts.count == 3 else { return prefix }
        // Drop leading zero from month/day
        let month = Int(parts[1]) ?? 0
        let day   = Int(parts[2]) ?? 0
        return "\(month)/\(day)"
    }

    private func chartLayout(size: CGSize) -> WeightChartLayout {
        let bounds = yDomain
        let gridStep = max((bounds.upperBound - bounds.lowerBound) / 3, 0.5)
        let gridValues = stride(from: bounds.lowerBound, through: bounds.upperBound, by: gridStep).map { $0 }

        return WeightChartLayout(
            leftInset: 4,
            rightInset: 4,
            topInset: 12,
            bottomInset: 24,
            minValue: bounds.lowerBound,
            maxValue: bounds.upperBound,
            gridValues: gridValues
        )
    }

    private func xPosition(for index: Int, count: Int, in layout: WeightChartLayout, width: CGFloat) -> CGFloat {
        guard count > 1 else { return layout.leftInset }
        let usableWidth = width - layout.leftInset - layout.rightInset
        let step = usableWidth / CGFloat(count - 1)
        return layout.leftInset + CGFloat(index) * step
    }

    private func yPosition(for value: Double, in layout: WeightChartLayout) -> CGFloat {
        let chartHeight = max(1, 160 - layout.topInset - layout.bottomInset)
        let progress = (value - layout.minValue) / (layout.maxValue - layout.minValue)
        return layout.topInset + chartHeight * CGFloat(1 - progress)
    }

    private func pointColor(for weight: Double) -> Color {
        if weight == minWeight { return AppTheme.info }
        if weight == maxWeight { return AppTheme.accent }
        return AppTheme.primary
    }

    private func shouldShowLabel(for index: Int, count: Int) -> Bool {
        guard count > 1 else { return true }
        let stride = max(1, count / 5)
        return index == 0 || index == count - 1 || index % stride == 0
    }
}

private struct WeightChartLayout {
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
    let sampleRecords: [WeightRecord] = [
        WeightRecord(id: 1,  weight: 72.5, recordedAt: "2024-01-01T08:00:00.000Z"),
        WeightRecord(id: 2,  weight: 72.1, recordedAt: "2024-01-04T08:00:00.000Z"),
        WeightRecord(id: 3,  weight: 71.8, recordedAt: "2024-01-07T08:00:00.000Z"),
        WeightRecord(id: 4,  weight: 71.5, recordedAt: "2024-01-10T08:00:00.000Z"),
        WeightRecord(id: 5,  weight: 71.9, recordedAt: "2024-01-13T08:00:00.000Z"),
        WeightRecord(id: 6,  weight: 71.2, recordedAt: "2024-01-16T08:00:00.000Z"),
        WeightRecord(id: 7,  weight: 70.8, recordedAt: "2024-01-19T08:00:00.000Z"),
        WeightRecord(id: 8,  weight: 70.5, recordedAt: "2024-01-22T08:00:00.000Z"),
        WeightRecord(id: 9,  weight: 70.9, recordedAt: "2024-01-25T08:00:00.000Z"),
        WeightRecord(id: 10, weight: 70.3, recordedAt: "2024-01-28T08:00:00.000Z"),
    ]
    return VStack {
        WeightLineChartView(records: sampleRecords)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(16)
            .padding()
    }
    .background(Color(red: 255/255, green: 249/255, blue: 240/255))
}
