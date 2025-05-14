import SwiftUI

@main
struct PeeriApp: App {
    @StateObject private var downloadManager = DownloadManager()
    
    init() {
        startAria2Daemon()
    }
    
    private func startAria2Daemon() {
        print("Starting aria2 daemon...")
        
        // Check if aria2 script exists in the bundle
        if let scriptPath = Bundle.main.path(forResource: "start_aria2", ofType: "sh") {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = [scriptPath]
            
            // Create a pipe to capture output
            let outputPipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = outputPipe
            
            do {
                try task.run()
                
                // Read output for debugging
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: outputData, encoding: .utf8) {
                    print("Aria2 daemon output: \(output)")
                }
                
                // Give aria2 some time to start up
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    print("Aria2 daemon should be running now")
                }
            } catch {
                print("Failed to start aria2 daemon: \(error)")
                self.installAndStartAria2Manually()
            }
        } else {
            print("Could not find start_aria2.sh script in bundle, using inline script")
            self.installAndStartAria2Manually()
        }
    }
    
    private func installAndStartAria2Manually() {
        print("Installing and starting aria2 manually...")
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        
        // Create .aria2 directory if it doesn't exist
        let aria2Dir = "\(homeDir)/.aria2"
        if !FileManager.default.fileExists(atPath: aria2Dir) {
            do {
                try FileManager.default.createDirectory(atPath: aria2Dir, withIntermediateDirectories: true)
            } catch {
                print("Failed to create .aria2 directory: \(error)")
                return
            }
        }
        
        // Create config file if it doesn't exist
        let configPath = "\(aria2Dir)/aria2.conf"
        if !FileManager.default.fileExists(atPath: configPath) {
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
            
            # Other settings
            check-integrity=true
            continue=true
            """
            
            do {
                try configContent.write(toFile: configPath, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to create aria2 config file: \(error)")
                return
            }
        }
        
        // Try to kill any existing aria2c processes
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
        
        // Start aria2c
        startAria2Daemon(configPath: configPath)
    }
    
    private func startAria2Daemon(configPath: String) {
        DispatchQueue.global(qos: .background).async {
            // Try to find aria2c executable
            let aria2cPath = self.findAria2cExecutable()
            
            if let executablePath = aria2cPath {
                print("Found aria2c at: \(executablePath)")
                
                do {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: executablePath)
                    task.arguments = ["--conf-path=\(configPath)"]
                    
                    let pipe = Pipe()
                    task.standardOutput = pipe
                    task.standardError = pipe
                    
                    try task.run()
                    
                    // Read output for debugging
                    DispatchQueue.global(qos: .background).async {
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        if let output = String(data: data, encoding: .utf8) {
                            print("Aria2 output: \(output)")
                        }
                    }
                    
                    print("Aria2 daemon started successfully")
                } catch {
                    print("Failed to start aria2c: \(error)")
                }
            } else {
                print("Could not find aria2c. Attempting to start Aria2 emulation mode...")
                self.startAria2EmulationMode()
            }
        }
    }
    
    private func findAria2cExecutable() -> String? {
        // Common locations for aria2c
        let possibleLocations = [
            "/usr/local/bin/aria2c",        // Homebrew Intel
            "/opt/homebrew/bin/aria2c",      // Homebrew Apple Silicon
            "/usr/bin/aria2c",              // System
            "/bin/aria2c",                  // Alternative system location
            "\(NSHomeDirectory())/.aria2/aria2c"  // User's .aria2 directory
        ]
        
        // Check each location
        for location in possibleLocations {
            if FileManager.default.fileExists(atPath: location) {
                return location
            }
        }
        
        // Try using which command
        do {
            let whichTask = Process()
            whichTask.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            whichTask.arguments = ["aria2c"]
            
            let whichPipe = Pipe()
            whichTask.standardOutput = whichPipe
            
            try whichTask.run()
            whichTask.waitUntilExit()
            
            let whichData = whichPipe.fileHandleForReading.readDataToEndOfFile()
            if let whichOutput = String(data: whichData, encoding: .utf8), !whichOutput.isEmpty {
                let path = whichOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                return path
            }
        } catch {
            print("Error using which command: \(error)")
        }
        
        return nil
    }
    
    private func startAria2EmulationMode() {
        print("Starting aria2 emulation mode - app will work but downloads won't be processed")
        
        // Set a notification to show when user tries to download
        NotificationCenter.default.post(
            name: NSNotification.Name("Aria2NotAvailable"),
            object: nil,
            userInfo: [
                "message": "Aria2 daemon not found. Install aria2 with Homebrew: brew install aria2"
            ]
        )
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
