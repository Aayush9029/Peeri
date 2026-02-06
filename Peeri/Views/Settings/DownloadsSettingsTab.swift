import Models
import Shared
import SwiftUI

struct DownloadsSettingsTab: View {
    @Shared(.settings) var settings

    var body: some View {
        Form {
            Section("Connection Settings") {
                HStack {
                    Text("Max Concurrent Downloads")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", value: Binding($settings.maxConcurrentDownloads), format: .number)
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
                    TextField("", value: Binding($settings.maxConnectionPerServer), format: .number)
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
                    TextField("", value: Binding($settings.split), format: .number)
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
                    TextField("", text: Binding($settings.minSplitSize))
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
                    TextField("", value: Binding($settings.maxOverallDownloadLimit), format: .number)
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
                    TextField("", value: Binding($settings.maxOverallUploadLimit), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("KB/s (0 = unlimited)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Advanced") {
                Toggle("Check File Integrity", isOn: Binding($settings.checkIntegrity))
                Toggle("Continue Incomplete Downloads", isOn: Binding($settings.continueDownloads))
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    DownloadsSettingsTab()
}
