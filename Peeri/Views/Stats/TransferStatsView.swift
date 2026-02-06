import Charts
import SwiftUI

struct TransferStatsView: View {
    let downloadRate: Int64
    let uploadRate: Int64
    let downloadHistory: [Double]
    let uploadHistory: [Double]
    let totalDownloaded: Int64
    let totalUploaded: Int64

    var body: some View {
        HStack {
            ZStack {
                TransferChart(numbers: normalizedHistory(downloadHistory), tint: .blue)
                TransferChart(numbers: normalizedHistory(uploadHistory), tint: .green)
            }
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
                HStack {
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
                    Spacer()
                }
                .font(.title2)
                Spacer()
            }.padding()
        }
    }

    private func normalizedHistory(_ history: [Double]) -> [Double] {
        let maxVal = history.max() ?? 1
        guard maxVal > 0 else { return history.map { _ in 0.0 } }
        return history.map { $0 / maxVal }
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

    var body: some View {
        VStack {
            ZStack {
                Chart {
                    ForEach(Array(numbers.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Value", value)
                        )
                        .interpolationMethod(.cardinal)
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

                Chart {
                    ForEach(Array(numbers.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Value", value)
                        )
                        .interpolationMethod(.cardinal)
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
