import SwiftUI

struct TransferActivityPreview: View {
    let downloads: [Double]
    let uploads: [Double]

    var body: some View {
        Canvas { context, size in
            let ceiling = max(downloads.max() ?? 0, uploads.max() ?? 0, 1024)
            for (samples, tint) in [(downloads, Color.blue), (uploads, Color.green)] {
                guard samples.count > 1 else { continue }
                let points = samples.enumerated().map { index, value in
                    CGPoint(
                        x: CGFloat(index) / CGFloat(samples.count - 1) * size.width,
                        y: size.height - 2 - CGFloat(max(0, value) / ceiling) * (size.height - 4)
                    )
                }
                let path = Path { path in
                    path.addLines(points)
                }
                context.stroke(path, with: .color(tint), style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
                if let last = points.last {
                    context.fill(Path(ellipseIn: CGRect(x: last.x - 1.5, y: last.y - 1.5, width: 3, height: 3)), with: .color(tint))
                }
            }
        }
        .frame(width: 64, height: 18)
        .accessibilityHidden(true)
    }
}
