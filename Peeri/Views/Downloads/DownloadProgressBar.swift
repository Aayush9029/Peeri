import Models
import SwiftUI

struct DownloadProgressBar: View {
    let progress: Double
    let status: DownloadStatus

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(fill)
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
        .frame(height: 6)
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
