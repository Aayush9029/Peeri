import SwiftUI

@main
struct PeeriApp: App {
    @StateObject private var downloadManager = DownloadManager()
    
    init() {
        startAria2Daemon()
    }
    
    private func startAria2Daemon() {
        print("Starting aria2 daemon using bundled executable...")
        
        // Get the path to the bundled aria2c executable
        // First check in main bundle
        var aria2cPath = Bundle.main.path(forResource: "aria2c", ofType: nil)
        
        // If not found in the main bundle, check if it's in the root directory
        if aria2cPath == nil {
            let rootPath = Bundle.main.bundlePath.deletingLastPathComponent
            let potentialPath = rootPath + "/aria2c"
            
            if FileManager.default.fileExists(atPath: potentialPath) {
                aria2cPath = potentialPath
                print("Found aria2c at root path: \(potentialPath)")
            }
        }
        
        // Use the provided executable or extract if needed
        let executablePath = aria2cPath ?? extractAria2cExecutable()
        print("Using aria2c executable at: \(executablePath)")
        
        // Create and configure the daemon
        setupAria2ConfigFile(using: executablePath)
    }
    
    // Extract aria2c executable if not found in bundle
    private func extractAria2cExecutable() -> String {
        print("Extracting embedded aria2c executable...")
        
        // Create a temporary directory for the executable
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("peeri_aria2c")
        let executablePath = tempDir.appendingPathComponent("aria2c").path
        
        do {
            // Create directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: tempDir.path) {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            }
            
            // Check if executable already exists at temp location
            if !FileManager.default.fileExists(atPath: executablePath) {
                // Copy from app bundle or bundle root (custom logic may be needed)
                // Here you would copy the embedded version
                
                // For now, we'll throw an error since we expect it to be in the bundle
                fatalError("aria2c executable not found in bundle or root directory. The app cannot function without it.")
            }
            
            // Ensure it's executable
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executablePath)
        } catch {
            print("Error extracting aria2c: \(error)")
            // Still return the path - we'll handle the error when trying to execute
        }
        
        return executablePath
    }
    
    private func setupAria2ConfigFile(using aria2cPath: String) {
        print("Setting up aria2 configuration...")
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        
        // Create logs directory if it doesn't exist
        let logsDir = "\(homeDir)/.peeri/logs"
        do {
            try FileManager.default.createDirectory(atPath: logsDir, withIntermediateDirectories: true)
        } catch {
            print("Failed to create logs directory: \(error)")
        }
        
        // Create .aria2 directory if it doesn't exist
        let aria2Dir = "\(homeDir)/.peeri/aria2"
        if !FileManager.default.fileExists(atPath: aria2Dir) {
            do {
                try FileManager.default.createDirectory(atPath: aria2Dir, withIntermediateDirectories: true)
            } catch {
                print("Critical error - failed to create aria2 directory: \(error)")
                fatalError("Cannot create required aria2 directory: \(error)")
            }
        }
        
        // Path to log file
        let logPath = "\(logsDir)/aria2c.log"
        
        // Create config file
        let configPath = "\(aria2Dir)/aria2.conf"
        let configContent = """
        # Basic configuration file for Aria2
        
        # Downloads directory
        dir=\(homeDir)/Downloads
        
        # Enable JSON-RPC server
        enable-rpc=true
        rpc-listen-all=true
        rpc-listen-port=6800
        rpc-secret=peeri
        
        # BitTorrent settings
        bt-enable-lpd=true
        bt-max-peers=50
        bt-request-peer-speed-limit=100K
        enable-peer-exchange=true
        
        # Connection settings
        max-concurrent-downloads=5
        max-connection-per-server=10
        max-overall-download-limit=0
        max-overall-upload-limit=50K
        min-split-size=1M
        split=10
        
        # Logging
        log=\(logPath)
        log-level=info
        
        # Other settings
        check-integrity=true
        continue=true
        """
        
        do {
            try configContent.write(toFile: configPath, atomically: true, encoding: .utf8)
            print("Created aria2 config file at \(configPath)")
        } catch {
            print("Critical error - failed to create aria2 config file: \(error)")
            fatalError("Cannot create required aria2 config file: \(error)")
        }
        
        // Kill any existing aria2c processes
        killExistingAria2Processes()
        
        // Start aria2c with our config
        startAria2Process(executablePath: aria2cPath, configPath: configPath, logPath: logPath)
    }
    
    private func killExistingAria2Processes() {
        print("Stopping any existing aria2c processes...")
        do {
            let killTask = Process()
            killTask.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            killTask.arguments = ["-f", "aria2c"]
            try killTask.run()
            killTask.waitUntilExit()
        } catch {
            print("Note: Failed to kill existing aria2c processes: \(error)")
            // Continue anyway
        }
    }
    
    private func startAria2Process(executablePath: String, configPath: String, logPath: String) {
        print("Starting aria2c process with executable at: \(executablePath)")
        
        // Make the aria2c executable file permissions correct
        do {
            let fileAttributes = [FileAttributeKey.posixPermissions: 0o755]
            try FileManager.default.setAttributes(fileAttributes, ofItemAtPath: executablePath)
        } catch {
            print("Warning: Could not set executable permissions on aria2c: \(error)")
            // Continue anyway
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Create process
                let task = Process()
                task.executableURL = URL(fileURLWithPath: executablePath)
                task.arguments = ["--conf-path=\(configPath)"]
                
                // Setup pipes for stdout and stderr
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                task.standardOutput = outputPipe
                task.standardError = errorPipe
                
                // Add termination handler
                task.terminationHandler = { process in
                    print("aria2c process terminated with status: \(process.terminationStatus)")
                    
                    // Auto-restart if the process terminates unexpectedly
                    if process.terminationStatus != 0 && process.terminationStatus != 15 {
                        print("Unexpected termination. Restarting aria2c...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.startAria2Process(executablePath: executablePath, configPath: configPath, logPath: logPath)
                        }
                    }
                }
                
                // Start the process
                try task.run()
                print("aria2c process started successfully with PID: \(task.processIdentifier)")
                
                // Create a handler to monitor the stdout of the process
                let outputFileHandle = outputPipe.fileHandleForReading
                outputFileHandle.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                        // Print any output from aria2c for debugging
                        print("aria2c output: \(output)")
                    }
                }
                
                // Create a handler to monitor the stderr of the process
                let errorFileHandle = errorPipe.fileHandleForReading
                errorFileHandle.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty, let error = String(data: data, encoding: .utf8) {
                        // Print any errors from aria2c
                        print("aria2c error: \(error)")
                    }
                }
            } catch {
                print("Error starting aria2c process: \(error)")
                print("Critical error - failed to start aria2c process - app cannot function properly without aria2c")
                fatalError("Failed to start aria2c process: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(downloadManager)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Download...") {
                    addDownload()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
    
    private func addDownload() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.text, .url]
        panel.prompt = "Add URL"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    if let fileContents = try? String(contentsOf: url), let downloadURL = URL(string: fileContents.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        await downloadManager.addDownload(url: downloadURL)
                    }
                }
            }
        }
    }
}
