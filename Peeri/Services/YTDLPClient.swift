import Foundation
import Models

struct YTDLPDownloadResult {
    let outputURL: URL?
}

struct YTDLPMetadata {
    let title: String?
    let thumbnailURL: URL?
}

struct YTDLPProgress: Sendable {
    let status: String?
    let downloadedBytes: Int64?
    let totalBytes: Int64?
    let totalBytesIsEstimate: Bool
    let speed: Int64?
    let eta: TimeInterval?

    var fraction: Double? {
        if status == "finished" { return 1 }
        guard let downloadedBytes, let totalBytes, totalBytes > 0 else { return nil }
        let value = Double(downloadedBytes) / Double(totalBytes)
        if totalBytesIsEstimate && value >= 0.995 { return nil }
        return value
    }
}

struct YTDLPClient {
    enum Failure: LocalizedError {
        case executableNotFound
        case launchFailed(String)

        var errorDescription: String? {
            switch self {
            case .executableNotFound:
                return "yt-dlp was not found in the app bundle."
            case let .launchFailed(message):
                return message
            }
        }
    }

    func canHandle(_ url: URL) -> Bool {
        VideoURLSupport.canHandle(url)
    }

    func version() async throws -> String {
        let output = try await run(arguments: ["--version"])
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func metadata(for url: URL) async throws -> YTDLPMetadata {
        let output = try await run(arguments: [
            "--no-playlist",
            "--print", "title",
            "--print", "thumbnail",
            url.absoluteString
        ])

        let lines = output
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        return YTDLPMetadata(
            title: lines.first,
            thumbnailURL: lines.dropFirst().first.flatMap(URL.init(string:))
        )
    }

    func download(
        url: URL,
        to directory: URL,
        formatPreference: VideoFormatPreference,
        onProgress: @escaping @Sendable (YTDLPProgress) async -> Void = { _ in }
    ) async throws -> YTDLPDownloadResult {
        let invocation = YTDLPInvocation(
            url: url,
            directory: directory,
            formatPreference: formatPreference
        )
        let output = try await run(
            arguments: invocation.arguments,
            onProgress: onProgress
        )

        let outputPath = output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .last { !Self.isProgressLine($0) && !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return YTDLPDownloadResult(outputURL: outputPath.map(URL.init(fileURLWithPath:)))
    }

    private func run(
        arguments: [String],
        onProgress: @escaping @Sendable (YTDLPProgress) async -> Void = { _ in }
    ) async throws -> String {
        let executableURL = try executableURL()
        let processBox = YTDLPProcessBox()

        return try await withTaskCancellationHandler {
            try await Task.detached(priority: .userInitiated) {
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executableURL.path)

                let task = Process()
                task.executableURL = executableURL
                task.arguments = arguments
                processBox.set(task)
                defer { processBox.clear() }

                let outputPipe = Pipe()
                let errorPipe = Pipe()
                task.standardOutput = outputPipe
                task.standardError = errorPipe

                try task.run()

                async let output = Self.collectOutput(
                    from: outputPipe.fileHandleForReading,
                    onProgress: onProgress
                )
                async let error = Self.collectOutput(
                    from: errorPipe.fileHandleForReading,
                    onProgress: onProgress
                )

                while task.isRunning {
                    if Task.isCancelled {
                        task.terminate()
                    }
                    try await Task.sleep(nanoseconds: 50_000_000)
                }

                let (outputString, errorString) = try await (output, error)

                try Task.checkCancellation()

                guard task.terminationStatus == 0 else {
                    let message = Self.nonProgressLines(in: errorString)
                        .joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    throw Failure.launchFailed(message.isEmpty ? "yt-dlp exited with status \(task.terminationStatus)." : message)
                }

                return outputString
            }.value
        } onCancel: {
            processBox.terminate()
        }
    }

    private static func collectOutput(
        from handle: FileHandle,
        onProgress: @escaping @Sendable (YTDLPProgress) async -> Void
    ) async throws -> String {
        var output = Data()
        var line = Data()

        for try await byte in handle.bytes {
            output.append(byte)

            if byte == 10 || byte == 13 {
                await process(line: line, onProgress: onProgress)
                line.removeAll(keepingCapacity: true)
            } else {
                line.append(byte)
            }
        }

        await process(line: line, onProgress: onProgress)
        return String(data: output, encoding: .utf8) ?? ""
    }

    private static func process(
        line: Data,
        onProgress: @escaping @Sendable (YTDLPProgress) async -> Void
    ) async {
        guard
            !line.isEmpty,
            let string = String(data: line, encoding: .utf8),
            let progress = progress(from: string)
        else { return }

        await onProgress(progress)
    }

    private static func nonProgressLines(in string: String) -> [String] {
        string
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !isProgressLine($0) }
    }

    private static func isProgressLine(_ line: String) -> Bool {
        progress(from: line) != nil
    }

    private static func progress(from line: String) -> YTDLPProgress? {
        guard let range = line.range(of: "peeri-progress:") else { return nil }
        let json = line[range.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(YTDLPProgressPayload.self, from: data).progress
    }

    private func executableURL() throws -> URL {
        if let bundled = Bundle.main.url(forResource: "yt-dlp", withExtension: nil) {
            return bundled
        }

        let sibling = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("yt-dlp")
        if FileManager.default.fileExists(atPath: sibling.path) {
            return sibling
        }

        throw Failure.executableNotFound
    }
}

private final class YTDLPProcessBox: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?

    func set(_ process: Process) {
        lock.withLock {
            self.process = process
        }
    }

    func clear() {
        lock.withLock {
            process = nil
        }
    }

    func terminate() {
        lock.withLock {
            guard process?.isRunning == true else { return }
            process?.terminate()
        }
    }
}

private struct YTDLPProgressPayload: Decodable {
    let status: String?
    let downloaded_bytes: Int64?
    let total_bytes: Int64?
    let total_bytes_estimate: Int64?
    let speed: Double?
    let eta: Double?

    var progress: YTDLPProgress {
        YTDLPProgress(
            status: status,
            downloadedBytes: downloaded_bytes,
            totalBytes: total_bytes ?? total_bytes_estimate,
            totalBytesIsEstimate: total_bytes == nil && total_bytes_estimate != nil,
            speed: speed.map(Int64.init),
            eta: eta
        )
    }
}
