import SwiftUI

struct VideoThumbnailBanner: View {
    let thumbnailURL: URL?

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: thumbnailURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.quaternary)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }
}
