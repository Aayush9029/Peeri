import Charts
import SwiftUI

struct TransferStatsView: View {
    let downloadRate: Int64
    let uploadRate: Int64
    let downloadHistory: [Double]
    let uploadHistory: [Double]
    let totalDownloaded: Int64
    let totalUploaded: Int64
    var allPaused: Bool = false

    private var hasUploadActivity: Bool {
        uploadHistory.contains(where: { $0 > 0 })
    }

    var body: some View {
        HStack(alignment: .top) {
            ZStack {
                TransferChart(numbers: downloadHistory, tint: .blue)
                if hasUploadActivity {
                    TransferChart(numbers: uploadHistory, tint: .green)
                }
            }
            .saturation(allPaused ? 0 : 1)
            .opacity(allPaused ? 0.5 : 1)

            VStack(alignment: .leading) {
                Text("DOWNLOAD / UPLOAD PER SEC")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack {
                    HStack {
                        Image(systemName: "arrow.down")
                        Text(formattedDownloadRate)
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "arrow.up")
                        Text(formattedUploadRate)
                    }
                }
                .font(.title.bold())
                Spacer()
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading) {
                        Text("Total Downloaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: totalDownloaded, countStyle: .binary))
                    }

                    VStack(alignment: .leading) {
                        Text("Total Uploaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: totalUploaded, countStyle: .binary))
                    }
                }
                .font(.title2)
                Spacer()
            }.padding()
        }
    }

    private var formattedDownloadRate: String {
        ByteCountFormatter.string(fromByteCount: downloadRate, countStyle: .binary) + "/s"
    }

    private var formattedUploadRate: String {
        ByteCountFormatter.string(fromByteCount: uploadRate, countStyle: .binary) + "/s"
    }
}

struct TransferChart: View {
    let numbers: [Double]
    let tint: Color

    private var maxValue: Double {
        max(numbers.max() ?? 0, 1024) * 1.25
    }

    var body: some View {
        VStack {
            ZStack {
                Chart {
                    ForEach(Array(numbers.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Value", value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(tint)
                        .lineStyle(.init(lineWidth: 6))

                        if index == (numbers.count - 1) {
                            PointMark(
                                x: .value("Index", index),
                                y: .value("Value", value)
                            )
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

                Chart {
                    ForEach(Array(numbers.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Value", value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(tint)

                        if index == (numbers.count - 1) {
                            PointMark(
                                x: .value("Index", index),
                                y: .value("Value", value)
                            )
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
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [.clear, .gray.opacity(0.125)], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
        )
    }
}
