import Foundation

/// Decodes aria2's hex-encoded piece bitfields. Each hex character encodes four
/// pieces, most-significant bit first, so piece `i` lives in nibble `i / 4` at
/// bit `3 - (i % 4)`.
public enum Bitfield {
    /// Per-piece download state for the first `count` pieces.
    public static func pieces(hex: String, count: Int) -> [Bool] {
        guard count > 0 else { return [] }
        let nibbles = Array(hex.utf8)
        return (0 ..< count).map { isSet($0, in: nibbles) }
    }

    /// Bucketed completion fractions (0...1) sized for a fixed grid. When the
    /// piece count exceeds `maxCells` each cell aggregates a contiguous range of
    /// pieces and reports the fraction of that range that is downloaded.
    public static func completion(hex: String?, count: Int, maxCells: Int) -> [Double] {
        guard count > 0 else { return [] }
        let cells = min(count, max(1, maxCells))
        var sums = [Double](repeating: 0, count: cells)
        var totals = [Double](repeating: 0, count: cells)
        let nibbles = hex.map { Array($0.utf8) }

        for piece in 0 ..< count {
            let cell = piece * cells / count
            totals[cell] += 1
            if let nibbles, isSet(piece, in: nibbles) {
                sums[cell] += 1
            }
        }

        return (0 ..< cells).map { totals[$0] > 0 ? sums[$0] / totals[$0] : 0 }
    }

    /// Fraction of pieces a peer reports having (0...1).
    public static func fractionSet(hex: String?, count: Int) -> Double {
        guard count > 0, let hex else { return 0 }
        let nibbles = Array(hex.utf8)
        var set = 0
        for piece in 0 ..< count where isSet(piece, in: nibbles) {
            set += 1
        }
        return Double(set) / Double(count)
    }

    private static func isSet(_ piece: Int, in nibbles: [UInt8]) -> Bool {
        let nibbleIndex = piece / 4
        guard nibbleIndex < nibbles.count else { return false }
        return (hexValue(nibbles[nibbleIndex]) >> (3 - piece % 4)) & 1 == 1
    }

    private static func hexValue(_ ascii: UInt8) -> Int {
        switch ascii {
        case 0x30 ... 0x39: return Int(ascii - 0x30)
        case 0x61 ... 0x66: return Int(ascii - 0x61 + 10)
        case 0x41 ... 0x46: return Int(ascii - 0x41 + 10)
        default: return 0
        }
    }
}
