import Models
import SwiftUI

struct DownloadProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progress: Double
    let status: DownloadStatus

    private var tint: Color {
        switch status {
        case .completed, .seeding: .green
        case .downloading: .blue
        case .failed: .red
        default: .gray
        }
    }

    private var isActive: Bool { status == .downloading || status == .seeding }
    private var clamped: Double { min(1, max(0, progress)) }

    var body: some View {
        GeometryReader { geometry in
            let fillWidth = clamped * geometry.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                TransferLight(tint: tint, animated: isActive)
                    .frame(width: fillWidth)
                    .clipShape(.capsule)
                    .shadow(color: tint.opacity(isActive ? 0.5 : 0), radius: 3)
                if isActive, clamped > 0.015, clamped < 0.995 {
                    Capsule()
                        .fill(.white)
                        .frame(width: 2)
                        .blur(radius: 1)
                        .opacity(0.8)
                        .offset(x: fillWidth - 2)
                }
            }
            .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: progress)
        }
        .frame(height: 6)
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}
