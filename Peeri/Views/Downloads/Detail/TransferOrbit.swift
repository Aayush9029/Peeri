import Models
import SwiftUI

struct TransferOrbit: View {
    let download: DownloadFile
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double { min(1, max(0, download.progress)) }

    var body: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
                .overlay {
                    Circle().fill(.linearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.35), lineWidth: 0.75)
                }
            Circle().strokeBorder(download.status.tint.opacity(0.13), lineWidth: 5)
            TransferLight(tint: download.status.tint, animated: download.status == .downloading || download.status == .seeding)
                .mask {
                    Circle().trim(from: 0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(2.5)
                }
                .shadow(color: download.status.tint.opacity(0.35), radius: 4)
            if progress > 0 && progress < 1 {
                Circle().fill(download.status.tint)
                    .frame(width: 5, height: 5)
                    .shadow(color: download.status.tint.opacity(0.6), radius: 5)
                    .offset(y: -37.5)
                    .rotationEffect(.degrees(progress * 360))
            }
            DownloadArtworkView(download: download, size: 40)
        }
        .frame(width: 80, height: 80)
        .animation(reduceMotion ? nil : .smooth(duration: 0.5), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Download progress")
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}
