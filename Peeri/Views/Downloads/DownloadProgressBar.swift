import Models
import SwiftUI

struct DownloadProgressBar: View {
    let progress: Double
    let status: DownloadStatus

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Capsule().fill(.quaternary)
                HStack {
                    Capsule()
                        .fill(fill)
                        .frame(width: max(0, geo.size.width * progress))
                    Spacer(minLength: 0)
                }

                if status == .downloading, progress > 0 {
                    shimmer(width: geo.size.width)
                }
            }
        }
        .frame(height: 8)
    }

    private var fill: AnyShapeStyle {
        switch status {
        case .completed, .seeding:
            AnyShapeStyle(LinearGradient(colors: [.green.opacity(0.8), .green], startPoint: .leading, endPoint: .trailing))
        case .downloading:
            AnyShapeStyle(LinearGradient(colors: [.blue.opacity(0.7), .blue], startPoint: .leading, endPoint: .trailing))
        default:
            AnyShapeStyle(Color.gray.opacity(0.5))
        }
    }

    private func shimmer(width: CGFloat) -> some View {
        TimelineView(.animation) { context in
            let duration = 1.15
            let phase = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: duration) / duration
            let fillWidth = max(0, width * progress)
            let shimmerWidth = max(28, width * 0.32)
            let travel = fillWidth + shimmerWidth * 2

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.42), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: shimmerWidth)
                .offset(x: -shimmerWidth + travel * phase)
                .mask(alignment: .leading) {
                    Capsule()
                        .frame(width: fillWidth)
                }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DownloadProgressBar(progress: 0.6, status: .downloading)
        DownloadProgressBar(progress: 1, status: .completed)
        DownloadProgressBar(progress: 0.3, status: .paused)
    }
    .frame(width: 220)
    .padding()
}
