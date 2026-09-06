import Charts
import SwiftUI

struct TransferChart: View {
    let samples: [Double]
    let tint: Color

    private var maxValue: Double {
        max(samples.max() ?? 0, 1024) * 1.2
    }

    var body: some View {
        Chart(Array(samples.enumerated()), id: \.offset) { index, value in
            AreaMark(
                x: .value("Time", index),
                y: .value("Rate", value)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(
                LinearGradient(
                    colors: [tint.opacity(0.35), tint.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Time", index),
                y: .value("Rate", value)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(tint)
            .lineStyle(.init(lineWidth: 2))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...maxValue)
        .accessibilityLabel("Transfer speed over the last 60 seconds")
    }
}
