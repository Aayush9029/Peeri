import Foundation
import Testing
import CustomDump
@testable import Models

@Suite("PeeriSettings Tests")
struct PeeriSettingsTests {
    @Test("Proxy addresses validate before replacing a working configuration")
    func proxyValidation() {
        expectNoDifference(Aria2Preferences.normalizedProxy("localhost:8080"), "http://localhost:8080")
        expectNoDifference(Aria2Preferences.normalizedProxy(""), "")
        #expect(Aria2Preferences.normalizedProxy("socks5://localhost:1080") == nil)
        #expect(Aria2Preferences.normalizedProxy("http://") == nil)
        #expect(Aria2Preferences.normalizedProxy("http://localhost:99999") == nil)
        #expect(Aria2Preferences.normalizedProxy("http://local host:8080") == nil)
    }

    @Test("New transfer preferences migrate and persist")
    func advancedPreferences() throws {
        var settings = try JSONDecoder().decode(PeeriSettings.self, from: Data("{}".utf8))
        expectNoDifference(settings.advanced, Aria2Preferences())
        settings.advanced.pieceOrder = "inorder"
        settings.advanced.prioritizePreview = true
        settings.advanced.requireEncryption = true
        settings.advanced.enableDHT = false
        settings.peerTargetSpeedKB = 250
        let restored = try JSONDecoder().decode(PeeriSettings.self, from: JSONEncoder().encode(settings))
        expectNoDifference(restored, settings)
        expectNoDifference(restored.toAria2DownloadOptions()["stream-piece-selector"], "inorder")
        expectNoDifference(restored.toAria2DownloadOptions()["bt-prioritize-piece"], "head=4M,tail=4M")
        expectNoDifference(restored.toAria2DownloadOptions()["bt-request-peer-speed-limit"], "250K")
        #expect(restored.toAria2ConfigString(logPath: "/tmp/test.log").contains("enable-dht=false"))
        #expect(restored.toAria2GlobalOptions()["enable-dht"] == nil)
    }

    @Test("Tracker policies preserve exact URLs and reject invalid entries")
    func trackerPolicy() {
        var settings = PeeriSettings()
        settings.advanced.trackers = "udp://tracker.example:80/announce\nhttps://tracker.example/announce\ninvalid"
        settings.advanced.excludedTrackers = "https://excluded.example/announce"
        expectNoDifference(settings.advanced.invalidTrackerEntries, ["invalid"])
        expectNoDifference(settings.toAria2DownloadOptions()["bt-tracker"], "udp://tracker.example:80/announce,https://tracker.example/announce")
        expectNoDifference(settings.toAria2DownloadOptions()["bt-exclude-tracker"], "https://excluded.example/announce")
        settings.advanced.onlyCustomTrackers = true
        expectNoDifference(settings.toAria2DownloadOptions()["bt-exclude-tracker"], "*")
        settings.advanced.onlyCustomTrackers = false
        expectNoDifference(settings.toAria2DownloadOptions()["bt-exclude-tracker"], "https://excluded.example/announce")
    }

    @Test("Network limits are bounded and cannot inject config lines")
    func networkValidation() {
        var settings = PeeriSettings()
        settings.advanced.connectTimeout = -1
        settings.advanced.listenPort = 99999
        settings.advanced.userAgent = "Peeri\nrpc-listen-all=true"
        settings.btMaxPeers = 0
        expectNoDifference(settings.toAria2DownloadOptions()["connect-timeout"], "1")
        expectNoDifference(settings.toAria2DownloadOptions()["bt-max-peers"], "0")
        let config = settings.toAria2ConfigString(logPath: "/tmp/test.log")
        #expect(config.contains("listen-port=65535"))
        #expect(!config.contains("\nrpc-listen-all=true"))
    }

    @Test("Decodes legacy min split size notation")
    func decodesLegacyMinSplitSizeNotation() throws {
        let data = try #require(#"{"minSplitSize":"512K"}"#.data(using: .utf8))
        let settings = try JSONDecoder().decode(PeeriSettings.self, from: data)

        #expect(settings.minSplitSize == 1)
    }

    @Test("Writes min split size as aria2 notation")
    func writesMinSplitSizeAsAria2Notation() {
        let settings = PeeriSettings(minSplitSize: 4)

        #expect(settings.toAria2GlobalOptions()["min-split-size"] == "4M")
    }

    @Test("Existing preferences migrate to bounded seeding")
    func migrateSeeding() throws {
        let settings = try JSONDecoder().decode(PeeriSettings.self, from: Data("{}".utf8))
        expectNoDifference(settings.seedingEnabled, true)
        expectNoDifference(settings.seedTimeMinutes, 120)
        expectNoDifference(settings.seedRatio, 1)
    }

    @Test("Disabling seeding preserves preferences but stops after completion")
    func disableSeeding() throws {
        let settings = PeeriSettings(seedingEnabled: false, seedTimeMinutes: 90, seedRatio: 2)
        expectNoDifference(settings.toAria2DownloadOptions()["seed-time"], "0")
        let restored = try JSONDecoder().decode(PeeriSettings.self, from: JSONEncoder().encode(settings))
        expectNoDifference(restored, settings)
    }

    @Test("Invalid numeric preferences cannot prevent engine startup")
    func invalidOptions() {
        let settings = PeeriSettings(maxConcurrentDownloads: -1, maxConnectionPerServer: 99, seedTimeMinutes: -100, seedRatio: .infinity)
        let options = settings.toAria2GlobalOptions()
        expectNoDifference(options["max-concurrent-downloads"], "1")
        expectNoDifference(options["max-connection-per-server"], "16")
        expectNoDifference(options["seed-time"], "1")
        expectNoDifference(options["seed-ratio"], "1.0")
        #expect(settings.toAria2ConfigString(logPath: "/tmp/aria2.log").contains("rpc-listen-all=false"))
    }
}
