import Charts
import SwiftUI

struct TransferChart: View {
    let numbers: [Double]
    let tint: Color

    private var maxValue: Double {
        max(numbers.max() ?? 0, 1024) * 1.25
    }

    var body: some View {
        ZStack {
            glowChart
            lineChart
        }
        .animation(.smooth(duration: 0.8), value: numbers)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(colors: [.clear, .gray.opacity(0.125)], startPoint: .leading, endPoint: .trailing),
                    lineWidth: 2
                )
        )
    }

    private var glowChart: some View {
        Chart {
            ForEach(Array(numbers.enumerated()), id: \.offset) { index, value in
                LineMark(x: .value("Index", index), y: .value("Value", value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(tint)
                    .lineStyle(.init(lineWidth: 6))

                if index == numbers.count - 1 {
                    PointMark(x: .value("Index", index), y: .value("Value", value))
                        .foregroundStyle(tint)
                        .shadow(color: tint, radius: 12)
                        .blur(radius: 32)
                }
            }
            .blur(radius: 42)
            .offset(y: 32)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...maxValue)
    }

    private var lineChart: some View {
        Chart {
            ForEach(Array(numbers.enumerated()), id: \.offset) { index, value in
                LineMark(x: .value("Index", index), y: .value("Value", value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(tint)

                if index == numbers.count - 1 {
                    PointMark(x: .value("Index", index), y: .value("Value", value))
                        .foregroundStyle(tint)
                        .shadow(color: tint, radius: 12)
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...maxValue)
        .saturation(1.25)
    }
}

#Preview {
    TransferChart(
        numbers: (0..<60).map { 1_000_000 * (1 + sin(Double($0) / 6)) },
        tint: .blue
    )
    .frame(width: 480, height: 200)
    .padding()
}
