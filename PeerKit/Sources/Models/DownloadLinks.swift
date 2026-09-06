import Foundation

public struct DownloadLinks: Equatable, Sendable {
    public let urls: [URL]
    public let invalidCount: Int
    public var isValid: Bool { !urls.isEmpty && invalidCount == 0 }

    public init(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        urls = lines.compactMap(Self.url)
        invalidCount = lines.count - urls.count
    }

    public var summary: String {
        guard let first = urls.first else { return "" }
        if urls.count > 1 { return "\(urls.count) links" }
        if first.scheme == "magnet" {
            return URLComponents(url: first, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "dn" })?.value ?? "Magnet link"
        }
        return first.host ?? first.absoluteString
    }

    private static func url(_ line: String) -> URL? {
        guard !line.contains(where: \.isWhitespace),
              let url = URL(string: line), let scheme = url.scheme?.lowercased(),
              ["http", "https", "ftp", "sftp", "magnet"].contains(scheme) else { return nil }
        if scheme == "magnet" {
            guard URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: {
                $0.name == "xt" && $0.value?.range(of: #"^urn:btih:([0-9a-fA-F]{40}|[a-zA-Z2-7]{32})$"#, options: .regularExpression) != nil
            }) == true else { return nil }
        } else if url.host?.isEmpty != false {
            return nil
        }
        return url
    }
}
