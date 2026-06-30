import Models
import SwiftUI

/// GitHub-contribution-style grid where each cell maps to a piece (or a
/// contiguous block of pieces for large torrents) shaded by how much of it has
/// downloaded.
struct PieceGridView: View {
    let bitfield: String?
    let numPieces: Int
    var isComplete: Bool = false
    var tint: Color = .green

    private let cellSize: CGFloat = 11
    private let spacing: CGFloat = 3
    private let maxCells = 2048

    @State private var availableWidth: CGFloat = 0

    private var cells: [Double] {
        if let bitfield {
            return Bitfield.completion(hex: bitfield, count: numPieces, maxCells: maxCells)
        }
        let count = min(numPieces, maxCells)
        return Array(repeating: isComplete ? 1 : 0, count: max(count, 0))
    }

    var body: some View {
        let cells = cells
        Canvas { context, size in
            let columns = columnCount(for: size.width)
            for index in cells.indices {
                let row = index / columns
                let column = index % columns
                let rect = CGRect(
                    x: CGFloat(column) * (cellSize + spacing),
                    y: CGFloat(row) * (cellSize + spacing),
                    width: cellSize,
                    height: cellSize
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 2.5),
                    with: .color(color(for: cells[index]))
                )
            }
        }
        .frame(height: gridHeight(for: availableWidth, cellCount: cells.count))
        .background(widthReader)
        .animation(.smooth(duration: 0.45), value: cells)
    }

    private var widthReader: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { availableWidth = geo.size.width }
                .onChange(of: geo.size.width) { _, newValue in availableWidth = newValue }
        }
    }

    private func color(for value: Double) -> Color {
        value <= 0 ? Color.gray.opacity(0.15) : tint.opacity(0.35 + 0.65 * value)
    }

    private func columnCount(for width: CGFloat) -> Int {
        max(1, Int((width + spacing) / (cellSize + spacing)))
    }

    private func gridHeight(for width: CGFloat, cellCount: Int) -> CGFloat {
        guard width > 0, cellCount > 0 else { return cellSize }
        let columns = columnCount(for: width)
        let rows = Int(ceil(Double(cellCount) / Double(columns)))
        return CGFloat(rows) * (cellSize + spacing) - spacing
    }
}

#Preview("Partial") {
    PieceGridView(bitfield: "ffffff00ff00ff0000", numPieces: 72)
        .padding()
        .frame(width: 420)
}

#Preview("Large") {
    PieceGridView(
        bitfield: String(repeating: "f", count: 600) + String(repeating: "0", count: 400),
        numPieces: 4000
    )
    .padding()
    .frame(width: 420)
}
