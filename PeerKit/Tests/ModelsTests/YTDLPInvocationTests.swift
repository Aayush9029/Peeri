import Foundation
import Testing
@testable import Models

@Suite("yt-dlp Invocation Tests")
struct YTDLPInvocationTests {
    @Test("Detects supported video hosts")
    func supportedHosts() throws {
        #expect(VideoURLSupport.canHandle(try #require(URL(string: "https://www.youtube.com/watch?v=z9eIgg0ArDg"))))
        #expect(VideoURLSupport.canHandle(try #require(URL(string: "https://youtu.be/z9eIgg0ArDg"))))
        #expect(VideoURLSupport.canHandle(try #require(URL(string: "https://player.vimeo.com/video/123"))))
    }

    @Test("Rejects non-video and non-web URLs")
    func unsupportedHosts() throws {
        #expect(!VideoURLSupport.canHandle(try #require(URL(string: "https://example.com/file.zip"))))
        #expect(!VideoURLSupport.canHandle(try #require(URL(string: "magnet:?xt=urn:btih:abc"))))
        #expect(!VideoURLSupport.canHandle(try #require(URL(string: "ftp://youtube.com/file"))))
    }

    @Test("Builds yt-dlp download arguments")
    func downloadArguments() throws {
        let invocation = YTDLPInvocation(
            url: try #require(URL(string: "https://www.youtube.com/watch?v=z9eIgg0ArDg")),
            directory: URL(fileURLWithPath: "/Users/example/Downloads"),
            formatPreference: .mp4
        )

        #expect(invocation.arguments == [
            "--no-playlist",
            "--newline",
            "--progress",
            "--progress-template", "download:peeri-progress:%(progress)j",
            "--windows-filenames",
            "--paths", "/Users/example/Downloads",
            "--output", "%(title).200B [%(id)s].%(ext)s",
            "--format", "best[ext=mp4]/best",
            "--print", "after_move:filepath",
            "https://www.youtube.com/watch?v=z9eIgg0ArDg"
        ])
    }

    @Test("Maps format preferences")
    func formatPreferenceMapping() {
        #expect(VideoFormatPreference.best.ytdlpFormat == "b")
        #expect(VideoFormatPreference.mp4.ytdlpFormat == "best[ext=mp4]/best")
        #expect(VideoFormatPreference.audioOnly.ytdlpFormat == "bestaudio[ext=m4a]/bestaudio/best")
    }
}
