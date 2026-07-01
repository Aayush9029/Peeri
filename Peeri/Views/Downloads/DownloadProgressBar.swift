import Models
import SwiftUI

struct DownloadProgressBar: View {
    let progress: Double
    let status: DownloadStatus

    var body: some View {
        GeometryReader { geo in
            let clampedProgress = max(0, min(1, progress))
            let fillWidth = clampedProgress * geo.size.width

            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(fill)
                    .frame(width: fillWidth)
                    .overlay {
                        if status == .downloading, fillWidth > 0 {
                            shimmer(width: fillWidth)
                        }
                    }
                    .clipShape(Capsule())
                    .animation(.spring(response: 0.35, dampingFraction: 0.82), value: clampedProgress)
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
            let shimmerWidth = max(28, width * 0.45)
            let travel = width + shimmerWidth * 2

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
        }
        .frame(width: width, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        DownloadProgressBar(progress: 0.6, status: .downloading)
        DownloadProgressBar(progress: 1, status: .completed)
        DownloadProgressBar(progress: 0.3, status: .paused)
    }
    .frame(width: 220)
    .padding()
}
#endif
