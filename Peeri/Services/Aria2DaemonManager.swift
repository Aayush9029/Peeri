import Foundation
import Models
import Shared
import os.log

@MainActor
final class Aria2DaemonManager {
    @ObservationIgnored
    @Shared(.settings) private var settings

    private var aria2Process: Process?
    private let logger = Logger(subsystem: "com.lovedoingthings.peeri", category: "Aria2DaemonManager")

    init() {
        start()
    }

    func start() {
        logger.info("Starting aria2 daemon…")
        let executablePath = findAria2Binary()
        logger.info("Using aria2c executable at: \(executablePath)")
        setupConfigFile(aria2cPath: executablePath)
    }

    func stop() {
        if let process = aria2Process, process.isRunning {
            process.terminate()
            logger.info("Terminated aria2c process (PID \(process.processIdentifier))")
        }
        aria2Process = nil
    }

    nonisolated deinit {
        // Process.terminate() is safe to call from any isolation context
    }

    // MARK: - Private Helpers

    private func findAria2Binary() -> String {
        // Check main bundle first
        if let bundled = Bundle.main.path(forResource: "aria2c", ofType: nil) {
            return bundled
        }

        // Fall back to root directory next to the .app bundle
        let bundlePath = Bundle.main.bundlePath
        let rootPath = (bundlePath as NSString).deletingLastPathComponent
        let potentialPath = rootPath + "/aria2c"

        if FileManager.default.fileExists(atPath: potentialPath) {
            logger.info("Found aria2c at root path: \(potentialPath)")
            return potentialPath
        }

        // Last resort: extract (currently just fatal-errors)
        return extractAria2cExecutable()
    }

    private func extractAria2cExecutable() -> String {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("peeri_aria2c")
        let executablePath = tempDir.appendingPathComponent("aria2c").path

        do {
            if !FileManager.default.fileExists(atPath: tempDir.path) {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            }

            if !FileManager.default.fileExists(atPath: executablePath) {
                fatalError("aria2c executable not found in bundle or root directory. The app cannot function without it.")
            }

            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executablePath)
        } catch {
            logger.error("Error extracting aria2c: \(error.localizedDescription)")
        }

        return executablePath
    }

    private func setupConfigFile(aria2cPath: String) {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let logsDir = "\(homeDir)/.peeri/logs"
        let aria2Dir = "\(homeDir)/.peeri/aria2"

        do {
            try FileManager.default.createDirectory(atPath: logsDir, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create logs directory: \(error.localizedDescription)")
        }

        if !FileManager.default.fileExists(atPath: aria2Dir) {
            do {
                try FileManager.default.createDirectory(atPath: aria2Dir, withIntermediateDirectories: true)
            } catch {
                fatalError("Cannot create required aria2 directory: \(error)")
            }
        }

        let logPath = "\(logsDir)/aria2c.log"
        let configPath = "\(aria2Dir)/aria2.conf"
        let configContent = settings.toAria2ConfigString(logPath: logPath)
        let downloadDirectory = DownloadDirectoryAccess(settings: settings)
        let didStartAccessing = downloadDirectory.startAccessing()

        do {
            try configContent.write(toFile: configPath, atomically: true, encoding: .utf8)
            logger.info("Created aria2 config at \(configPath)")
        } catch {
            fatalError("Cannot create required aria2 config file: \(error)")
        }

        killExistingProcesses()
        launchProcess(
            executablePath: aria2cPath,
            configPath: configPath,
            logPath: logPath,
            downloadDirectory: downloadDirectory,
            didStartAccessingDownloadDirectory: didStartAccessing
        )
    }

    private func killExistingProcesses() {
        logger.info("Stopping any existing aria2c processes…")
        do {
            let killTask = Process()
            killTask.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            killTask.arguments = ["-f", "aria2c"]
            try killTask.run()
            killTask.waitUntilExit()
        } catch {
            logger.warning("Could not kill existing aria2c processes: \(error.localizedDescription)")
        }
    }

    private func launchProcess(
        executablePath: String,
        configPath: String,
        logPath: String,
        downloadDirectory: DownloadDirectoryAccess? = nil,
        didStartAccessingDownloadDirectory: Bool = false
    ) {
        logger.info("Launching aria2c at \(executablePath)")

        do {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executablePath)
        } catch {
            logger.warning("Could not set executable permissions on aria2c: \(error.localizedDescription)")
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: executablePath)
                task.arguments = ["--conf-path=\(configPath)"]

                let outputPipe = Pipe()
                let errorPipe = Pipe()
                task.standardOutput = outputPipe
                task.standardError = errorPipe

                task.terminationHandler = { [weak self] process in
                    guard let self else { return }
                    self.logger.info("aria2c terminated with status \(process.terminationStatus)")

                    // Auto-restart on unexpected termination (skip normal exit and SIGTERM)
                    if process.terminationStatus != 0 && process.terminationStatus != 15 {
                        self.logger.warning("Unexpected termination — restarting aria2c in 2s…")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            let didStartAccessing = downloadDirectory?.startAccessing() ?? false
                            self.launchProcess(
                                executablePath: executablePath,
                                configPath: configPath,
                                logPath: logPath,
                                downloadDirectory: downloadDirectory,
                                didStartAccessingDownloadDirectory: didStartAccessing
                            )
                        }
                    }
                }

                try task.run()
                self.logger.info("aria2c started (PID \(task.processIdentifier))")
                downloadDirectory?.stopAccessing(didStartAccessingDownloadDirectory)

                DispatchQueue.main.async {
                    self.aria2Process = task
                }

                outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                    let data = handle.availableData
                    if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                        self?.logger.debug("aria2c stdout: \(output)")
                    }
                }

                errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                    let data = handle.availableData
                    if !data.isEmpty, let error = String(data: data, encoding: .utf8) {
                        self?.logger.error("aria2c stderr: \(error)")
                    }
                }
            } catch {
                downloadDirectory?.stopAccessing(didStartAccessingDownloadDirectory)
                self.logger.critical("Failed to start aria2c: \(error.localizedDescription)")
                fatalError("Failed to start aria2c process: \(error)")
            }
        }
    }
}
