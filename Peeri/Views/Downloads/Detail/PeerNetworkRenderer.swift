import SwiftUI

struct PeerNetworkRenderer {
    let peers: [PeerDisplay]
    let locations: [String: PeerLocation]
    let highlightedPeerID: PeerDisplay.ID?
    let time: TimeInterval
    let animate: Bool
    let strongContrast: Bool
    let translucent: Bool

    func draw(in context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2 - 2)
        let horizontalRadius = max(0, size.width / 2 - 26)
        let verticalRadius = max(0, size.height / 2 - 30)
        let hasTraffic = peers.contains { $0.downloadSpeed > 0 || $0.uploadSpeed > 0 }

        for (index, peer) in peers.enumerated() {
            let angle = Double(index) / Double(max(1, peers.count)) * 2 * .pi - .pi * 0.78
            let spread = 0.84 + Double(index % 3) * 0.08
            let end = CGPoint(
                x: center.x + cos(angle) * horizontalRadius * spread,
                y: center.y + sin(angle) * verticalRadius * spread
            )
            let start = CGPoint(x: center.x + cos(angle) * 12, y: center.y + sin(angle) * 12)
            let bend = 20.0 + Double(index % 4) * 5
            let control = CGPoint(
                x: (start.x + end.x) / 2 - sin(angle) * bend,
                y: (start.y + end.y) / 2 + cos(angle) * bend
            )
            let active = peer.downloadSpeed > 0 || peer.uploadSpeed > 0
            let tint: Color = peer.downloadSpeed > 0 ? .blue : .teal
            let dimmed = highlightedPeerID != nil && highlightedPeerID != peer.id
            var connection = context
            connection.opacity = dimmed ? 0.18 : 1
            var path = Path()
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
            connection.stroke(
                path,
                with: .color(active ? tint.opacity(strongContrast ? 0.65 : 0.22) : .secondary.opacity(strongContrast ? 0.5 : 0.16)),
                style: StrokeStyle(lineWidth: strongContrast ? 1.2 : 0.8, lineCap: .round)
            )

            if animate {
                drawFlow(in: connection, start: end, control: control, end: start, rate: peer.downloadSpeed, phase: Double(index) * 0.23, tint: .blue)
                drawFlow(in: connection, start: start, control: control, end: end, rate: peer.uploadSpeed, phase: Double(index) * 0.31 + 0.5, tint: .teal)
            }

            if active && translucent {
                connection.fill(circle(at: end, radius: 8), with: .radialGradient(Gradient(colors: [tint.opacity(0.16), .clear]), center: end, startRadius: 0, endRadius: 8))
            }
            connection.fill(circle(at: end, radius: active ? 2.8 : 2.2), with: .color(active ? tint : .secondary.opacity(0.7)))
            if peers.count <= 10, let label = locationLabel(for: peer.ip) {
                let anchor = CGPoint(x: end.x, y: end.y + (sin(angle) > 0 ? 13 : -13))
                connection.draw(Text(label).font(.system(size: 9, weight: .medium)).foregroundColor(.secondary), at: anchor)
            }
        }

        if hasTraffic && translucent {
            context.fill(circle(at: center, radius: 24), with: .radialGradient(Gradient(colors: [.blue.opacity(0.12), .clear]), center: center, startRadius: 2, endRadius: 24))
        }
        context.fill(circle(at: center, radius: 5), with: .color(.primary.opacity(0.85)))
        context.stroke(circle(at: center, radius: 8), with: .color(.primary.opacity(strongContrast ? 0.4 : 0.1)), lineWidth: 0.75)
        let labelY = peers.count > 3 ? size.height - 6 : center.y + 24
        context.draw(Text("This Mac").font(.system(size: 10, weight: .medium)).foregroundColor(.secondary), at: CGPoint(x: center.x, y: labelY))
    }

    private func drawFlow(in context: GraphicsContext, start: CGPoint, control: CGPoint, end: CGPoint, rate: Int64, phase: Double, tint: Color) {
        guard rate > 0 else { return }
        let intensity = min(1, log2(Double(rate) + 1) / 22)
        let duration = 3.4 - intensity * 1.4
        let position = (time / duration + phase).truncatingRemainder(dividingBy: 1)
        let tail = max(0, position - 0.2)
        let headPoint = point(on: start, control: control, end: end, fraction: position)
        let tailPoint = point(on: start, control: control, end: end, fraction: tail)
        var trail = Path()
        trail.move(to: tailPoint)
        for step in 1...8 {
            trail.addLine(to: point(on: start, control: control, end: end, fraction: tail + (position - tail) * Double(step) / 8))
        }
        context.stroke(trail, with: .linearGradient(Gradient(colors: [.clear, tint.opacity(0.85)]), startPoint: tailPoint, endPoint: headPoint), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        context.fill(circle(at: headPoint, radius: 1.2 + intensity * 0.7), with: .color(tint))
    }

    private func locationLabel(for ip: String) -> String? {
        switch locations[ip] {
        case let .country(code): code
        case .localNetwork: "Local"
        case .unavailable, .none: nil
        }
    }

    private func circle(at center: CGPoint, radius: Double) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }

    private func point(on start: CGPoint, control: CGPoint, end: CGPoint, fraction: Double) -> CGPoint {
        let remaining = 1 - fraction
        return CGPoint(
            x: remaining * remaining * start.x + 2 * remaining * fraction * control.x + fraction * fraction * end.x,
            y: remaining * remaining * start.y + 2 * remaining * fraction * control.y + fraction * fraction * end.y
        )
    }
}
