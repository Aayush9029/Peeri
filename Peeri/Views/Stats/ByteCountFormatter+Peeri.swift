import Foundation

extension ByteCountFormatter {
    /// Renders byte counts numerically (0 → "0 KB", not "Zero KB").
    static func peeri(_ count: Int64, style: ByteCountFormatter.CountStyle = .binary) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = style
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: count)
    }
}
