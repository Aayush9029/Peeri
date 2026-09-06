import Foundation

public struct Aria2Preferences: Codable, Equatable, Sendable {
    public var pieceOrder = "default"
    public var prioritizePreview = false
    public var enableDHT = true
    public var enableDHT6 = false
    public var enableIPv6 = true
    public var requireEncryption = false
    public var seedOutsideQueue = true
    public var trackers = ""
    public var excludedTrackers = ""
    public var trackerBlocklists: TrackerBlocklists?
    public var onlyCustomTrackers = false
    public var listenPort = 6881
    public var connectTimeout = 60
    public var timeout = 60
    public var maxTries = 5
    public var retryWait = 5
    public var proxy = ""
    public var proxyBypass = ""
    public var userAgent = ""
    public var preserveTimestamp = false
    public var autoRename = true
    public var fileAllocation = "prealloc"
    public var ftpPassive = true
    public var reuseConnections = true

    public init() {}

    public var downloadOptions: [String: String] {
        var options = [
            "stream-piece-selector": ["default", "inorder", "random", "geom"].contains(pieceOrder) ? pieceOrder : "default",
            "bt-prioritize-piece": prioritizePreview ? "head=4M,tail=4M" : "",
            "bt-force-encryption": String(requireEncryption),
            "bt-detach-seed-only": String(seedOutsideQueue),
            "bt-tracker": Self.entries(trackers).filter(Self.isTracker).filter { !blockedTrackers.contains($0) }.joined(separator: ","),
            "bt-exclude-tracker": onlyCustomTrackers ? "*" : Self.trackerList(excludedTrackers + "\n" + blockedTrackers.sorted().joined(separator: "\n")),
            "connect-timeout": String(max(1, min(connectTimeout, 600))),
            "timeout": String(max(1, min(timeout, 600))),
            "max-tries": String(max(0, min(maxTries, 100))),
            "retry-wait": String(max(0, min(retryWait, 600))),
            "all-proxy": Self.singleLine(proxy),
            "no-proxy": Self.entries(proxyBypass).joined(separator: ","),
            "remote-time": String(preserveTimestamp),
            "auto-file-renaming": String(autoRename),
            "file-allocation": ["none", "prealloc", "trunc"].contains(fileAllocation) ? fileAllocation : "prealloc",
            "ftp-pasv": String(ftpPassive),
            "enable-http-keep-alive": String(reuseConnections)
        ]
        options["user-agent"] = userAgent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "aria2/1.37.0" : Self.singleLine(userAgent)
        return options
    }

    private var blockedTrackers: Set<String> {
        Set(trackerBlocklists?.excludedURLs ?? [])
    }

    public static func normalizedProxy(_ value: String) -> String? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return "" }
        guard !value.contains(where: { $0.isWhitespace }) else { return nil }
        let normalized = value.contains("://") ? value : "http://" + value
        guard let url = URLComponents(string: normalized),
              url.scheme?.lowercased() == "http",
              let host = url.host, !host.isEmpty,
              url.path.isEmpty || url.path == "/",
              url.query == nil, url.fragment == nil,
              url.port.map({ (1...65535).contains($0) }) ?? true else { return nil }
        return normalized
    }

    public var invalidTrackerEntries: [String] {
        Self.entries(trackers + "\n" + excludedTrackers).filter { !Self.isTracker($0) }
    }

    private static func trackerList(_ value: String) -> String {
        entries(value).filter(isTracker).joined(separator: ",")
    }

    private static func isTracker(_ value: String) -> Bool {
        guard let url = URL(string: value), let scheme = url.scheme, let host = url.host else { return false }
        return ["http", "https", "udp"].contains(scheme.lowercased()) && !host.isEmpty
    }

    private static func entries(_ value: String) -> [String] {
        value.components(separatedBy: CharacterSet(charactersIn: ",\n\r"))
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private static func singleLine(_ value: String) -> String {
        value.components(separatedBy: .newlines).joined().trimmingCharacters(in: .whitespaces)
    }
}
