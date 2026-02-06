import Models
import Shared
import SwiftUI

struct DownloadsSettingsTab: View {
    @Shared(.settings) var settings
    @State private var maxConcurrentDownloads: Int
    @State private var maxConnectionPerServer: Int
    @State private var split: Int
    @State private var minSplitSize: String
    @State private var maxOverallDownloadLimit: Int
    @State private var maxOverallUploadLimit: Int
    @State private var checkIntegrity: Bool
    @State private var continueDownloads: Bool

    init() {
        let settings = Shared(.settings).wrappedValue
        _maxConcurrentDownloads = State(initialValue: settings.maxConcurrentDownloads)
        _maxConnectionPerServer = State(initialValue: settings.maxConnectionPerServer)
        _split = State(initialValue: settings.split)
        _minSplitSize = State(initialValue: settings.minSplitSize)
        _maxOverallDownloadLimit = State(initialValue: settings.maxOverallDownloadLimit)
        _maxOverallUploadLimit = State(initialValue: settings.maxOverallUploadLimit)
        _checkIntegrity = State(initialValue: settings.checkIntegrity)
        _continueDownloads = State(initialValue: settings.continueDownloads)
    }

    var body: some View {
        Form {
            Section("Connection Settings") {
                HStack {
                    Text("Max Concurrent Downloads")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", value: $maxConcurrentDownloads, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("(1-16)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Max Connections per Server")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", value: $maxConnectionPerServer, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("(1-16)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Split Chunks per File")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", value: $split, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("(1-16)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Minimum Split Size")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", text: $minSplitSize)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("(e.g., 1M, 5M)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Speed Limits") {
                HStack {
                    Text("Max Download Speed")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", value: $maxOverallDownloadLimit, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("KB/s (0 = unlimited)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Max Upload Speed")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", value: $maxOverallUploadLimit, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("KB/s (0 = unlimited)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Advanced") {
                Toggle("Check File Integrity", isOn: $checkIntegrity)
                Toggle("Continue Incomplete Downloads", isOn: $continueDownloads)
            }
        }
        .formStyle(.grouped)
        .onChange(of: maxConcurrentDownloads) { _, newValue in
            $settings.withLock { $0.maxConcurrentDownloads = newValue }
        }
        .onChange(of: maxConnectionPerServer) { _, newValue in
            $settings.withLock { $0.maxConnectionPerServer = newValue }
        }
        .onChange(of: split) { _, newValue in
            $settings.withLock { $0.split = newValue }
        }
        .onChange(of: minSplitSize) { _, newValue in
            $settings.withLock { $0.minSplitSize = newValue }
        }
        .onChange(of: maxOverallDownloadLimit) { _, newValue in
            $settings.withLock { $0.maxOverallDownloadLimit = newValue }
        }
        .onChange(of: maxOverallUploadLimit) { _, newValue in
            $settings.withLock { $0.maxOverallUploadLimit = newValue }
        }
        .onChange(of: checkIntegrity) { _, newValue in
            $settings.withLock { $0.checkIntegrity = newValue }
        }
        .onChange(of: continueDownloads) { _, newValue in
            $settings.withLock { $0.continueDownloads = newValue }
        }
    }
}

#Preview {
    DownloadsSettingsTab()
}
