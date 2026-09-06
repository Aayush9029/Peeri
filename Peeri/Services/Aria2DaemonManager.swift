import Foundation
import Models
import Shared
import os

@MainActor
final class Aria2DaemonManager {
    @Shared(.settings) private var settings
    private var process: Process?
    private var restartTask: Task<Void, Never>?
    private var isStopping = false
    private let logger = Logger(subsystem: "com.lovedoingthings.peeri", category: "Daemon")

    init() {
        start()
    }

    func start() {
        guard process?.isRunning != true else { return }
        isStopping = false
        do {
            guard let executable = Bundle.main.url(forResource: "aria2c", withExtension: nil) else {
                throw CocoaError(.fileNoSuchFile)
            }
            let root = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".peeri/aria2")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let session = root.appending(path: "session.txt")
            if !FileManager.default.fileExists(atPath: session.path) {
                try Data().write(to: session)
            }
            let config = root.appending(path: "aria2.conf")
            try settings.toAria2ConfigString(logPath: root.appending(path: "aria2.log").path)
                .write(to: config, atomically: true, encoding: .utf8)

            let task = Process()
            task.executableURL = executable
            task.arguments = [
                "--conf-path=\(config.path)",
                "--input-file=\(session.path)",
                "--save-session=\(session.path)",
                "--save-session-interval=5",
                "--force-save=true",
                "--stop-with-process=\(ProcessInfo.processInfo.processIdentifier)"
            ]
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            task.terminationHandler = { [weak self] terminated in
                let status = terminated.terminationStatus
                Task { @MainActor [weak self] in
                    guard let self, !isStopping else { return }
                    logger.error("aria2 exited with status \(status)")
                    restartTask = Task { [weak self] in
                        do { try await Task.sleep(for: .seconds(3)) } catch { return }
                        self?.start()
                    }
                }
            }
            try task.run()
            process = task
        } catch {
            logger.error("Could not start aria2: \(error.localizedDescription)")
        }
    }

    func stop() {
        isStopping = true
        restartTask?.cancel()
        if let process, process.isRunning { process.terminate() }
        process = nil
    }
}
