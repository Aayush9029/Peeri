import Foundation
import Testing
@testable import Models

@Suite("DownloadModel Tests")
struct DownloadModelTests {
    @Test("Progress computation")
    func downloadFileProgress() {
        var file = DownloadFile(
            gid: "abc123",
            url: URL(string: "https://example.com/file.zip")!,
            fileName: "file.zip",
            fileSize: 1000,
            downloadedSize: 500
        )
        #expect(file.progress == 0.5)

        file.downloadedSize = 1000
        #expect(file.progress == 1.0)

        file.downloadedSize = 0
        #expect(file.progress == 0.0)
    }

    @Test("Progress with nil fileSize returns 0")
    func progressNilFileSize() {
        let file = DownloadFile(
            gid: "abc123",
            url: URL(string: "https://example.com/file.zip")!,
            fileName: "file.zip",
            fileSize: nil,
            downloadedSize: 500
        )
        #expect(file.progress == 0.0)
    }

    @Test("Progress with zero fileSize returns 0")
    func progressZeroFileSize() {
        let file = DownloadFile(
            gid: "abc123",
            url: URL(string: "https://example.com/file.zip")!,
            fileName: "file.zip",
            fileSize: 0,
            downloadedSize: 0
        )
        #expect(file.progress == 0.0)
    }

    @Test("Codable round-trip")
    func downloadFileCodable() throws {
        let original = DownloadFile(
            id: .deterministic(from: "deadbeef12345678"),
            gid: "deadbeef12345678",
            url: URL(string: "https://example.com/test.zip")!,
            fileName: "test.zip",
            filePath: "/Downloads/test.zip",
            fileSize: 1048576,
            downloadedSize: 524288,
            downloadSpeed: 65536,
            uploadSpeed: 1024,
            status: .downloading
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(DownloadFile.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.gid == original.gid)
        #expect(decoded.url == original.url)
        #expect(decoded.fileName == original.fileName)
        #expect(decoded.filePath == original.filePath)
        #expect(decoded.fileSize == original.fileSize)
        #expect(decoded.downloadedSize == original.downloadedSize)
        #expect(decoded.downloadSpeed == original.downloadSpeed)
        #expect(decoded.uploadSpeed == original.uploadSpeed)
        #expect(decoded.status == original.status)
    }

    @Test("Deterministic UUID from GID")
    func deterministicUUID() {
        let gid = "2089b05ecca3d829"
        let uuid1 = DownloadFile.ID.deterministic(from: gid)
        let uuid2 = DownloadFile.ID.deterministic(from: gid)

        // Same GID always produces same UUID
        #expect(uuid1 == uuid2)
        #expect(uuid1.rawValue.uuidString == "2089B05E-CCA3-D829-0000-000000000000")

        // Different GID produces different UUID
        let uuid3 = DownloadFile.ID.deterministic(from: "abc123def4567890")
        #expect(uuid1 != uuid3)
    }

    @Test("Deterministic UUID handles short GIDs")
    func deterministicUUIDShort() {
        let uuid = DownloadFile.ID.deterministic(from: "abc")
        #expect(uuid.rawValue.uuidString == "ABC00000-0000-0000-0000-000000000000")
    }

    @Test("DownloadStatus raw values")
    func downloadStatusMapping() {
        #expect(DownloadStatus.pending.rawValue == "pending")
        #expect(DownloadStatus.downloading.rawValue == "downloading")
        #expect(DownloadStatus.paused.rawValue == "paused")
        #expect(DownloadStatus.completed.rawValue == "completed")
        #expect(DownloadStatus.failed.rawValue == "failed")
    }

    @Test("DownloadFile Hashable conformance")
    func downloadFileHashable() {
        let file1 = DownloadFile(
            gid: "abc123",
            url: URL(string: "https://example.com/file.zip")!,
            fileName: "file.zip"
        )
        let file2 = DownloadFile(
            gid: "abc123",
            url: URL(string: "https://example.com/file.zip")!,
            fileName: "file.zip"
        )

        #expect(file1 != file2)

        // Same tagged id and values means equal
        let file3 = DownloadFile(
            id: .deterministic(from: "abc"),
            gid: "abc",
            url: URL(string: "https://example.com/file.zip")!,
            fileName: "file.zip"
        )
        let file4 = DownloadFile(
            id: .deterministic(from: "abc"),
            gid: "abc",
            url: URL(string: "https://example.com/file.zip")!,
            fileName: "file.zip"
        )
        #expect(file3 == file4)
    }
}
