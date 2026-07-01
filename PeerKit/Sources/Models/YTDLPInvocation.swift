import Foundation

public enum VideoURLSupport {
    public static func canHandle(_ url: URL) -> Bool {
        guard
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            let host = url.host(percentEncoded: false)?.lowercased()
        else { return false }

        return host == "youtu.be"
            || host == "youtube.com"
            || host.hasSuffix(".youtube.com")
            || host == "vimeo.com"
            || host.hasSuffix(".vimeo.com")
    }
}

public struct YTDLPInvocation: Equatable, Sendable {
    public let url: URL
    public let directory: URL
    public let formatPreference: VideoFormatPreference

    public init(
        url: URL,
        directory: URL,
        formatPreference: VideoFormatPreference
    ) {
        self.url = url
        self.directory = directory
        self.formatPreference = formatPreference
    }

    public var arguments: [String] {
        [
            "--no-playlist",
            "--newline",
            "--progress",
            "--progress-template", "download:peeri-progress:%(progress)j",
            "--windows-filenames",
            "--paths", directory.path,
            "--output", "%(title).200B [%(id)s].%(ext)s",
            "--format", formatPreference.ytdlpFormat,
            "--print", "after_move:filepath",
            url.absoluteString
        ]
    }
}

public extension VideoFormatPreference {
    var ytdlpFormat: String {
        switch self {
        case .best:
            "b"
        case .mp4:
            "best[ext=mp4]/best"
        case .audioOnly:
            "bestaudio[ext=m4a]/bestaudio/best"
        }
    }
}
