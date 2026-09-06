import AppKit
import SwiftUI

struct TransferLight: View {
    let tint: Color
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Rectangle()
            .fill(tint)
            .overlay {
                LinearGradient(
                    colors: [.white.opacity(0.28), .white.opacity(0.02), .black.opacity(0.14)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay {
                TransferSweep(active: animated && !reduceMotion)
            }
            .accessibilityHidden(true)
    }
}

private struct TransferSweep: NSViewRepresentable {
    let active: Bool

    func makeNSView(context _: Context) -> TransferSweepView { TransferSweepView() }

    func updateNSView(_ view: TransferSweepView, context _: Context) {
        view.isActive = active
    }
}

/// SwiftUI does not redraw `Table` cell content continuously, so a `TimelineView`
/// driven shader freezes there. Core Animation runs on the render server and keeps
/// the sweep moving regardless.
final class TransferSweepView: NSView {
    private let sweep = CAGradientLayer()

    var isActive = true {
        didSet { if isActive != oldValue { updateAnimation() } }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        sweep.startPoint = CGPoint(x: 0, y: 0.5)
        sweep.endPoint = CGPoint(x: 1, y: 0.5)
        sweep.colors = [
            NSColor.white.withAlphaComponent(0).cgColor,
            NSColor.white.withAlphaComponent(0.28).cgColor,
            NSColor.white.withAlphaComponent(0.85).cgColor,
            NSColor.white.withAlphaComponent(0.28).cgColor,
            NSColor.white.withAlphaComponent(0).cgColor
        ]
        sweep.locations = [0, 0.35, 0.5, 0.65, 1]
        layer?.addSublayer(sweep)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sweep.bounds = CGRect(x: 0, y: 0, width: max(bounds.width * 0.6, 24), height: bounds.height)
        sweep.position = CGPoint(x: -sweep.bounds.width, y: bounds.midY)
        CATransaction.commit()
        updateAnimation()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateAnimation()
    }

    private func updateAnimation() {
        sweep.removeAnimation(forKey: "sweep")
        guard isActive, window != nil, bounds.width > 0 else {
            sweep.isHidden = true
            return
        }
        sweep.isHidden = false
        let travel = CABasicAnimation(keyPath: "position.x")
        travel.fromValue = -sweep.bounds.width / 2
        travel.toValue = bounds.width + sweep.bounds.width / 2
        travel.duration = 1.9
        travel.repeatCount = .infinity
        sweep.add(travel, forKey: "sweep")
    }
}
