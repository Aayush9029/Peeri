import SwiftUI

public enum PeeryAsset {
    // We'll add specific assets here later
}

public extension Image {
    static func asset(_ asset: PeeryAsset) -> Image {
        // Implementation to be added
        return Image(systemName: "arrow.down.circle")
    }
}

public extension Color {
    static let peeryPrimary = Color.blue
    static let peerySecondary = Color.indigo
    static let peeryBackground = Color(nsColor: .windowBackgroundColor)
}