import Foundation

public enum TrackerBlocklistCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case flagged
    case malfunctioning
    case duplicates

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .flagged: "Flagged trackers"
        case .malfunctioning: "Broken or misleading trackers"
        case .duplicates: "Duplicate trackers"
        }
    }
    public var detail: String {
        switch self {
        case .flagged: "Reported by antivirus software in the community list."
        case .malfunctioning: "Trackers listed with errors, malfunctions, or fake seed counts."
        case .duplicates: "Alternate announce URLs listed as duplicates."
        }
    }
}

public struct TrackerBlocklists: Codable, Equatable, Sendable {
    public var enabled: Set<TrackerBlocklistCategory> = []
    public var entries: [TrackerBlocklistCategory: [String]] = [:]
    public var updatedAt: Date?
    public init() {}

    public var excludedURLs: [String] {
        Array(Set(enabled.flatMap { entries[$0] ?? [] })).sorted()
    }

    public mutating func update(from text: String, at date: Date = Date()) throws {
        var parsed: [TrackerBlocklistCategory: [String]] = [:]
        for line in text.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: " # ")
            guard parts.count == 2 else { continue }
            let address = parts[0].trimmingCharacters(in: .whitespaces)
            guard let url = URL(string: address), let host = url.host, !host.isEmpty,
                  ["http", "https", "udp"].contains(url.scheme?.lowercased() ?? ""),
                  !address.contains(where: \.isWhitespace), !address.contains(",") else { continue }
            let reason = parts[1].lowercased()
            let category: TrackerBlocklistCategory?
            if reason.contains("antivirus") { category = .flagged }
            else if ["error", "malfunction", "fake seeds"].contains(reason) { category = .malfunctioning }
            else if reason.hasPrefix("duplicate of ") { category = .duplicates }
            else { category = nil }
            if let category { parsed[category, default: []].append(address) }
        }
        guard !parsed.isEmpty else { throw ParseError.emptyList }
        entries = parsed.mapValues { Array(Set($0)).sorted() }
        updatedAt = date
    }

    public enum ParseError: Error { case emptyList }
}
