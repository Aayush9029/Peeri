import SwiftUI

struct PeeriDial: View {
    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let value: Int
    let range: ClosedRange<Int>
    var unit = ""
    var step = 1
    let onChange: (Int) -> Void

    private var fraction: Double {
        Double(value - range.lowerBound) / Double(max(1, range.upperBound - range.lowerBound))
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.linearGradient(colors: [.white.opacity(0.07), .black.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay { Circle().strokeBorder(.white.opacity(0.08), lineWidth: 0.5) }
                    .padding(12)
                Circle().stroke(.quaternary, lineWidth: 7).padding(4)
                TransferLight(tint: .accentColor, animated: isHovering)
                    .mask {
                        Circle()
                            .trim(from: 0, to: min(1, max(0, fraction)))
                            .stroke(style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .padding(4)
                    }
                ForEach(0..<24) { index in
                    Capsule()
                        .fill(.tertiary)
                        .frame(width: 1, height: 4)
                        .offset(y: -35)
                        .rotationEffect(.degrees(Double(index) * 15))
                }
                VStack(spacing: 1) {
                    Text(value, format: .number)
                        .font(.system(size: 24, weight: .medium, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText())
                    if !unit.isEmpty {
                        Text(unit).font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 100, height: 100)
            .contentShape(.circle)
            .onHover { isHovering = $0 }
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                let point = gesture.location
                var angle = atan2(point.x - 50, 50 - point.y)
                if angle < 0 { angle += 2 * .pi }
                let raw = Double(range.lowerBound) + angle / (2 * .pi) * Double(range.upperBound - range.lowerBound)
                commit(Int((raw / Double(step)).rounded()) * step)
            })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue("\(value) \(unit)")
            .accessibilityAdjustableAction { direction in
                commit(value + (direction == .increment ? step : -step))
            }
            HStack(spacing: 10) {
                Button { commit(value - step) } label: { Image(systemName: "minus") }
                    .disabled(value <= range.lowerBound)
                    .accessibilityLabel("Decrease \(title)")
                Text(title).font(.caption.weight(.medium))
                Button { commit(value + step) } label: { Image(systemName: "plus") }
                    .disabled(value >= range.upperBound)
                    .accessibilityLabel("Increase \(title)")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .animation(reduceMotion ? nil : .smooth(duration: 0.2), value: value)
    }

    private func commit(_ value: Int) {
        onChange(min(range.upperBound, max(range.lowerBound, value)))
    }
}
