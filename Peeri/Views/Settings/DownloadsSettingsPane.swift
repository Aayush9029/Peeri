import Models
import Shared
import SwiftUI

struct DownloadsSettingsPane: View {
    @Shared(.settings) private var settings

    var body: some View {
        SettingsForm {
            Section("Connections") {
                HStack {
                    PeeriDial(title: "Downloads", value: settings.maxConcurrentDownloads, range: 1...16) { value in
                        $settings.withLock { $0.maxConcurrentDownloads = value }
                    }
                    PeeriDial(title: "Connections", value: settings.maxConnectionPerServer, range: 1...16) { value in
                        $settings.withLock { $0.maxConnectionPerServer = value }
                    }
                    PeeriDial(title: "Chunks", value: settings.split, range: 1...16) { value in
                        $settings.withLock { $0.split = value }
                    }
                }

                HStack(spacing: 10) {
                    Text("Minimum Split Size")
                    Spacer()
                    HStack(spacing: 10) {
                        Slider(value: minSplitSizeValue, in: 1 ... 64, step: 1)
                            .accessibilityLabel("Minimum split size")
                            .frame(width: 170)

                        Text("\(settings.minSplitSize) MB")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .trailing)
                    }
                }
                Text("Minimum size of each split chunk.")
                    .settingDescription()
            }

            Section("Speed Limits") {
                LabeledContent("Max Download Speed") {
                    speedField("Download limit", value: Binding($settings.maxOverallDownloadLimit))
                }

                LabeledContent("Max Upload Speed") {
                    speedField("Upload limit", value: Binding($settings.maxOverallUploadLimit))
                }

                Text("Values are in KB/s. Use 0 for unlimited.")
                    .settingDescription()
            }

            Section("Download Order") {
                Picker("Web & FTP pieces", selection: Binding($settings.advanced.pieceOrder)) {
                    Text("Automatic").tag("default")
                    Text("Beginning first").tag("inorder")
                    Text("Preview, then spread out").tag("geom")
                    Text("Random").tag("random")
                }
                Text("Beginning first requests pieces in order. Parallel connections may still finish pieces out of order. Torrent preview priority is in BitTorrent settings.")
                    .settingDescription()
            }
            Section("Files") {
                Toggle("Rename files when a name is taken", isOn: Binding($settings.advanced.autoRename))
                Toggle("Preserve server timestamps", isOn: Binding($settings.advanced.preserveTimestamp))
                Picker("Allocate disk space", selection: Binding($settings.advanced.fileAllocation)) {
                    Text("Reserve before downloading").tag("prealloc")
                    Text("Set file size only").tag("trunc")
                    Text("As needed").tag("none")
                }
                Text("These preferences apply to new downloads.")
                    .settingDescription()
            }
        }
    }

    private var minSplitSizeValue: Binding<Double> {
        Binding(
            get: { Double(settings.minSplitSize) },
            set: { newValue in
                $settings.withLock {
                    $0.minSplitSize = Int(newValue.rounded())
                }
            }
        )
    }

    private func speedField(_ title: String, value: Binding<Int>) -> some View {
        HStack(spacing: 6) {
            TextField(title, value: value, format: .number)
                .labelsHidden()
                .accessibilityLabel(title)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 92)
            Text("KB/s")
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }
}
