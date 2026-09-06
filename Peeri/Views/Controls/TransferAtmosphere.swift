import SwiftUI

struct TransferAtmosphere: View {
    let tint: Color
    let animated: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.controlActiveState) private var controlActiveState

    var body: some View {
        if !reduceTransparency {
            GeometryReader { geometry in
                TimelineView(.animation(minimumInterval: 1.0 / 24, paused: reduceMotion || !animated || controlActiveState == .inactive)) { context in
                    Rectangle()
                        .fill(.white)
                        .colorEffect(ShaderLibrary.transferAtmosphere(
                            .float2(geometry.size.width, geometry.size.height),
                            .float(reduceMotion || !animated ? 0 : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 50 * .pi)),
                            .color(tint)
                        ))
                        .opacity(colorScheme == .dark ? 0.65 : 0.32)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
