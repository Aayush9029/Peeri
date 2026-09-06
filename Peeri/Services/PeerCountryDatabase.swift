import Darwin
import Foundation

struct PeerCountryDatabase: Sendable {
    private let data: Data
    private let ipv4Count: Int
    private let ipv6Count: Int
    private let ipv6Offset: Int

    init(data: Data) throws {
        guard data.count >= 16, data.prefix(8) == Data("PEERIC01".utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let ipv4Count = data[8..<12].reduce(0) { $0 << 8 | Int($1) }
        let ipv6Count = data[12..<16].reduce(0) { $0 << 8 | Int($1) }
        let ipv6Offset = 16 + ipv4Count * 10
        guard ipv6Offset + ipv6Count * 34 == data.count else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
        self.ipv4Count = ipv4Count
        self.ipv6Count = ipv6Count
        self.ipv6Offset = ipv6Offset
    }

    func location(for ip: String) -> PeerLocation {
        let address = String(ip.split(separator: "%", maxSplits: 1).first ?? "")
        guard !address.utf8.contains(0) else { return .unavailable }
        var ipv4 = in_addr()
        if inet_pton(AF_INET, address, &ipv4) == 1 {
            return ipv4Location(Array(withUnsafeBytes(of: &ipv4) { Data($0) }))
        }
        var ipv6 = in6_addr()
        guard inet_pton(AF_INET6, address, &ipv6) == 1 else { return .unavailable }
        let bytes = Array(withUnsafeBytes(of: &ipv6) { Data($0) })
        if bytes.prefix(10).allSatisfy({ $0 == 0 }), bytes[10] == 255, bytes[11] == 255 {
            return ipv4Location(Array(bytes.suffix(4)))
        }
        if bytes.dropLast().allSatisfy({ $0 == 0 }), bytes[15] == 1 { return .localNetwork }
        if bytes[0] & 0xfe == 0xfc || (bytes[0] == 0xfe && bytes[1] & 0xc0 >= 0x80) {
            return .localNetwork
        }
        guard bytes[0] & 0xe0 == 0x20 else { return .unavailable }
        if bytes.prefix(4) == [0x20, 0x01, 0x0d, 0xb8] { return .unavailable }
        return lookup(bytes, offset: ipv6Offset, count: ipv6Count)
    }

    private func ipv4Location(_ bytes: [UInt8]) -> PeerLocation {
        let a = bytes[0]
        let b = bytes[1]
        let c = bytes[2]
        if a == 10 || a == 127 || (a == 172 && (16...31).contains(b)) ||
            (a == 192 && b == 168) || (a == 169 && b == 254) {
            return .localNetwork
        }
        guard a > 0, a < 224,
              !(a == 100 && (64...127).contains(b)),
              !(a == 192 && b == 0 && (c == 0 || c == 2)),
              !(a == 198 && (b == 18 || b == 19 || (b == 51 && c == 100))),
              !(a == 203 && b == 0 && c == 113) else { return .unavailable }
        return lookup(bytes, offset: 16, count: ipv4Count)
    }

    private func lookup(_ address: [UInt8], offset: Int, count: Int) -> PeerLocation {
        let width = address.count
        let stride = width * 2 + 2
        var lower = 0
        var upper = count
        return data.withUnsafeBytes { bytes in
            while lower < upper {
                let middle = lower + (upper - lower) / 2
                let record = offset + middle * stride
                let start = UnsafeRawBufferPointer(rebasing: bytes[record..<(record + width)])
                if address.lexicographicallyPrecedes(start) {
                    upper = middle
                } else {
                    lower = middle + 1
                }
            }
            guard lower > 0 else { return .unavailable }
            let record = offset + (lower - 1) * stride
            let end = UnsafeRawBufferPointer(rebasing: bytes[(record + width)..<(record + width * 2)])
            guard !end.lexicographicallyPrecedes(address) else { return .unavailable }
            let code = String(decoding: bytes[(record + width * 2)..<(record + stride)], as: UTF8.self)
            return code == "ZZ" ? .unavailable : .country(code)
        }
    }
}
