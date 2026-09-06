import Foundation

enum PeerLocation: Equatable, Sendable {
    case country(String)
    case localNetwork
    case unavailable

    var name: String? {
        switch self {
        case let .country(code): Locale.current.localizedString(forRegionCode: code) ?? code
        case .localNetwork: "Local network"
        case .unavailable: nil
        }
    }

    var flag: String? {
        guard case let .country(code) = self, code.utf8.count == 2 else { return nil }
        return String(String.UnicodeScalarView(code.unicodeScalars.compactMap {
            UnicodeScalar(127397 + $0.value)
        }))
    }
}
