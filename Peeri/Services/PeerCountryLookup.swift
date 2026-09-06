import Foundation

actor PeerCountryLookup {
    static let shared = PeerCountryLookup()

    private var database: PeerCountryDatabase?
    private var didLoad = false
    private var cache: [String: PeerLocation] = [:]

    func locations(for addresses: [String]) -> [String: PeerLocation] {
        if !didLoad {
            didLoad = true
            if let url = Bundle.main.url(forResource: "PeerCountries", withExtension: "bin"),
               let data = try? Data(contentsOf: url, options: .mappedIfSafe) {
                database = try? PeerCountryDatabase(data: data)
            }
        }
        if cache.count > 4096 { cache.removeAll(keepingCapacity: true) }
        var result: [String: PeerLocation] = [:]
        for address in Set(addresses) {
            let location = cache[address] ?? database?.location(for: address) ?? .unavailable
            cache[address] = location
            result[address] = location
        }
        return result
    }
}
