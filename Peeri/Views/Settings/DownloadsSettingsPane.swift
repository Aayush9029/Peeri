import Models
import Shared
import SwiftUI

struct DownloadsSettingsPane: View {
    @Shared(.settings) private var settings

    var body: some View {
        Form {
            Section("Connections") {
                Stepper(value: Binding($settings.maxConcurrentDownloads), in: 1 ... 16) {
                    LabeledContent("Concurrent Downloads", value: "\(settings.maxConcurrentDownloads)")
                }

                Stepper(value: Binding($settings.maxConnectionPerServer), in: 1 ... 16) {
                    LabeledContent("Connections per Server", value: "\(settings.maxConnectionPerServer)")
                }

                Stepper(value: Binding($settings.split), in: 1 ... 16) {
                    LabeledContent("Split Chunks per File", value: "\(settings.split)")
                }

                LabeledContent("Minimum Split Size") {
                    TextField("1M", text: Binding($settings.minSplitSize))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                Text("Use aria2 size notation, for example 1M or 512K.")
                    .settingDescription()
            }

            Section("Speed Limits") {
                LabeledContent("Max Download Speed") {
                    speedField(value: Binding($settings.maxOverallDownloadLimit))
                }

                LabeledContent("Max Upload Speed") {
                    speedField(value: Binding($settings.maxOverallUploadLimit))
                }

                Text("Values are in KB/s. Use 0 for unlimited.")
                    .settingDescription()
            }

            Section("Advanced") {
                Toggle("Check file integrity", isOn: Binding($settings.checkIntegrity))
                Toggle("Continue incomplete downloads", isOn: Binding($settings.continueDownloads))
            }
        }
        .formStyle(.grouped)
    }

    private func speedField(value: Binding<Int>) -> some View {
        HStack(spacing: 6) {
            TextField("0", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 92)
            Text("KB/s")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DownloadsSettingsPane()
}
