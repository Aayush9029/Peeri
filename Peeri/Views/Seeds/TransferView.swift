//
//  TransferView.swift
//  Peeri
//
//  Created by Aayush Pokharel on 2023-05-09.
//
import Charts
import SwiftUI

struct TransferView: View {
    var body: some View {
        HStack {
            ZStack {
                TransferChart(numbers: [0.35, 0.18, 0.2], tint: .teal)
                TransferChart(numbers: [0.05, 0.08, 0.23], tint: .green)
            }
            VStack(alignment: .leading) {
                Text("DOWNLOAD / UPLOAD PER SEC")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack {
                    HStack {
                        Image(systemName: "arrow.down")
                        Text("14.0MB")
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "arrow.up")
                        Text("11.5MB")
                    }
                }
                .font(.title.bold())
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading) {
                            Text("Seeds")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("12")
                        }

                        VStack(alignment: .leading) {
                            Text("Downloaded")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("800 MB")
                        }

                        VStack(alignment: .leading) {
                            Text("Time elapsed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("8 min 41 sec")
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading) {
                            Text("Down / up ratio")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("1.2")
                        }

                        VStack(alignment: .leading) {
                            Text("Uploaded")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("228 MB")
                        }
                        VStack(alignment: .leading) {
                            Text("Time left")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("1 min 12 sec")
                        }
                    }
                }
                .font(.title2)
                Spacer()
            }.padding()
        }
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

struct TransferView_Previews: PreviewProvider {
    static var previews: some View {
        TransferView()
            .padding()
            .background(.black)
            .cornerRadius(18)
            .padding()
    }
}
