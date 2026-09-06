import Darwin
import Foundation

@main struct Checks {
    static func main() throws {
        let db = try PeerCountryDatabase(data: fixture())
        for ip in ["127.0.0.1", "10.1.2.3", "172.16.0.0", "172.31.255.255", "192.168.2.1", "169.254.42.1", "::1", "fc00::1", "fd12::1", "fe80::1%en0", "::ffff:192.168.1.1"] {
            precondition(db.location(for: ip) == .localNetwork, ip)
        }
        for ip in ["", "no address", "999.1.1.1", "8.8.8.8\0invalid", "0.0.0.0", "100.64.0.1", "192.0.2.1", "198.18.1.1", "198.51.100.1", "203.0.113.1", "224.1.1.1", "255.255.255.255", "::", "ff02::1", "2001:db8::1", "1.0.4.0", "8.8.7.255", "2001:485f:ffff:ffff:ffff:ffff:ffff:ffff"] {
            precondition(db.location(for: ip) == .unavailable, ip)
        }
        for ip in ["8.8.8.8", "8.8.4.4", "::ffff:8.8.8.8"] {
            precondition(db.location(for: ip) == .country("US"), "Unexpected location for \(ip): \(db.location(for: ip))")
        }
        precondition(db.location(for: "2001:4860:4860::8888") == .country("CA"))
        precondition(db.location(for: "1.0.0.0") == .country("AU"))
        precondition(db.location(for: "1.0.0.255") == .country("AU"))
        precondition(db.location(for: "1.0.1.0") == .country("CN"))
        for data in [Data(), Data("PEERIC01".utf8), Data(repeating: 0, count: 16), Data("PEERIC01".utf8) + Data(repeating: 255, count: 8)] {
            do {
                _ = try PeerCountryDatabase(data: data)
                fatalError("Accepted corrupt database")
            } catch {}
        }
        _ = try PeerCountryDatabase(data: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        print("Country lookup checks passed, and bundled database format is valid.")
    }

    private static func fixture() -> Data {
        var data = Data("PEERIC01".utf8) + Data([0, 0, 0, 4, 0, 0, 0, 1])
        for (start, end, country) in [
            ("1.0.0.0", "1.0.0.255", "AU"),
            ("1.0.1.0", "1.0.3.255", "CN"),
            ("8.8.4.0", "8.8.4.255", "US"),
            ("8.8.8.0", "8.8.8.255", "US"),
            ("2001:4860::", "2001:4860:ffff:ffff:ffff:ffff:ffff:ffff", "CA")
        ] {
            data.append(address(start))
            data.append(address(end))
            data.append(Data(country.utf8))
        }
        return data
    }

    private static func address(_ text: String) -> Data {
        var bytes = [UInt8](repeating: 0, count: text.contains(":") ? 16 : 4)
        precondition(inet_pton(text.contains(":") ? AF_INET6 : AF_INET, text, &bytes) == 1)
        return Data(bytes)
    }
}
