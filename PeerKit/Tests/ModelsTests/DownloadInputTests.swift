import Foundation
import Models
import Testing

@Suite struct DownloadInputTests {
    @Test func clipboardLinksRequireEveryLineToBeValid() {
        #expect(DownloadLinks("https://example.com/file.zip\nftp://example.com/file").isValid)
        #expect(!DownloadLinks("https://example.com/file.zip\nprivate clipboard note").isValid)
        #expect(!DownloadLinks("").isValid)
        #expect(!DownloadLinks("https://example.com/a b").isValid)
        #expect(!DownloadLinks("file:///etc/hosts").isValid)
    }

    @Test func magnetValidationAndDisplayName() {
        let links = DownloadLinks("magnet:?xt=urn:btih:0123456789abcdef0123456789abcdef01234567&dn=Example%20Download")
        #expect(links.isValid)
        #expect(links.summary == "Example Download")
        #expect(!DownloadLinks("magnet:?xt=urn:btih:invalid").isValid)
    }

    @Test func blocklistsSeparateReasonsAndPreserveCacheOnBadResponse() throws {
        var lists = TrackerBlocklists()
        try lists.update(from: """
        https://flagged.example/announce # detected by antivirus software
        udp://broken.example:80/announce # malfunction
        https://duplicate.example/announce # duplicate of https://other.example/announce
        https://restricted.example/announce # registered torrents
        https://redirect.example/announce # redirects to https://other.example/announce
        """)
        lists.enabled = [.flagged, .malfunctioning]
        #expect(lists.excludedURLs.count == 2)
        #expect(!lists.excludedURLs.contains("https://restricted.example/announce"))
        let cached = lists
        #expect(throws: TrackerBlocklists.ParseError.self) { try lists.update(from: "<html>unavailable</html>") }
        #expect(lists == cached)
    }

    @Test func blocklistsFilterAdditionalTrackersAndCanBeDisabled() throws {
        var preferences = Aria2Preferences()
        var lists = TrackerBlocklists()
        try lists.update(from: "https://blocked.example/announce # detected by antivirus software")
        lists.enabled = [.flagged]
        preferences.trackerBlocklists = lists
        preferences.trackers = "https://blocked.example/announce\nhttps://allowed.example/announce"
        #expect(preferences.downloadOptions["bt-tracker"] == "https://allowed.example/announce")
        #expect(preferences.downloadOptions["bt-exclude-tracker"] == "https://blocked.example/announce")
        preferences.trackerBlocklists?.enabled = []
        #expect(preferences.downloadOptions["bt-tracker"]?.contains("blocked.example") == true)
        #expect(preferences.downloadOptions["bt-exclude-tracker"] == "")
    }

    @Test func oldAdvancedSettingsKeepTheirValues() throws {
        var old = Aria2Preferences()
        old.listenPort = 7000
        old.prioritizePreview = true
        let decoded = try JSONDecoder().decode(Aria2Preferences.self, from: JSONEncoder().encode(old))
        #expect(decoded.listenPort == 7000)
        #expect(decoded.prioritizePreview)
        #expect(decoded.trackerBlocklists == nil)
    }
    @Test func destinationSurvivesPersistenceAndOlderDownloadsStillDecode() throws {
        let download = DownloadFile(url: URL(string: "https://example.com/video.mp4")!, fileName: "video.mp4", destinationDirectory: "/tmp/Peeri Downloads")
        let data = try JSONEncoder().encode(download)
        #expect(try JSONDecoder().decode(DownloadFile.self, from: data).destinationDirectory == "/tmp/Peeri Downloads")
        var legacy = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        legacy.removeValue(forKey: "destinationDirectory")
        let restored = try JSONDecoder().decode(DownloadFile.self, from: JSONSerialization.data(withJSONObject: legacy))
        #expect(restored.destinationDirectory == nil)
        #expect(restored.fileName == "video.mp4")
    }

    @Test func videoTitlesAreSeparateFromFilenames() throws {
        var video = DownloadFile(gid: "yt-dlp:test", url: URL(string: "https://youtube.com/watch?v=example123")!, fileName: "A video [example123].webm")
        #expect(video.displayName == "A video")
        video.videoTitle = "A Video: Original Title"
        #expect(video.displayName == "A Video: Original Title")
        #expect(video.fileName == "A video [example123].webm")
        #expect(try JSONDecoder().decode(DownloadFile.self, from: JSONEncoder().encode(video)).videoTitle == video.videoTitle)
    }

}
