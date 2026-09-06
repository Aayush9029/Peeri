import SwiftUI
import UI

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 12
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        Group {
            if reduceTransparency || contrast == .increased {
                content.background(Color(nsColor: .controlBackgroundColor))
            } else {
                content.universalGlassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    .linearGradient(
                        colors: [.white.opacity(colorScheme == .dark ? 0.32 : 0.75), .white.opacity(0.08), .white.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: contrast == .increased ? 1 : 0.75
                )
                .allowsHitTesting(false)
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
    }
}
