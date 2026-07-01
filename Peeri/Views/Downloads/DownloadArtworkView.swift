import Models
import SwiftUI

struct DownloadArtworkView: View {
    let download: DownloadFile
    let size: CGFloat

    private var width: CGFloat { size * 1.6 }
    private var cornerRadius: CGFloat { min(12, size * 0.2) }

    init(download: DownloadFile, size: CGFloat = 30) {
        self.download = download
        self.size = size
    }

    var body: some View {
        if let thumbnailURL = download.thumbnailURL {
            thumbnail(thumbnailURL)
                .accessibilityHidden(true)
        } else {
            fallbackIcon
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }

    private func thumbnail(_ thumbnailURL: URL) -> some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallbackIcon
                case .empty:
                    ProgressView()
                        .controlSize(.mini)
                @unknown default:
                    fallbackIcon
                }
            }
            .frame(width: width, height: size)
            .background(.quaternary, in: .rect(cornerRadius: cornerRadius))
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.quaternary, lineWidth: 0.5)
            }

            Circle()
                .fill(download.status.tint)
                .frame(width: max(8, size * 0.27), height: max(8, size * 0.27))
                .overlay {
                    Circle().stroke(.background, lineWidth: max(1.5, size * 0.05))
                }
                .offset(x: 1, y: 1)
        }
        .frame(width: width, height: size)
    }

    private var fallbackIcon: some View {
        Image(systemName: download.status.symbol)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(download.status.tint)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        DownloadArtworkView(download: .sampleDownloading)
        DownloadArtworkView(download: .sampleCompleted)
        DownloadArtworkView(download: .sampleFailed)
    }
    .padding()
}
#endif
