import Models
import Shared
import SwiftUI

struct DownloadsSettingsPane: View {
    @Shared(.settings) private var settings

    var body: some View {
        Form {
            Section("Connections") {
                stepperRow(
                    "Concurrent Downloads",
                    value: Binding($settings.maxConcurrentDownloads),
                    range: 1 ... 16
                )

                stepperRow(
                    "Connections per Server",
                    value: Binding($settings.maxConnectionPerServer),
                    range: 1 ... 16
                )

                stepperRow(
                    "Split Chunks per File",
                    value: Binding($settings.split),
                    range: 1 ... 16
                )

                LabeledContent("Minimum Split Size") {
                    HStack(spacing: 10) {
                        Slider(value: minSplitSizeValue, in: 1 ... 64, step: 1)
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

    private func stepperRow(
        _ title: LocalizedStringKey,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Text(value.wrappedValue, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 24, alignment: .trailing)

                Stepper(title, value: value, in: range)
                    .labelsHidden()
            }
        }
    }

    private func speedField(value: Binding<Int>) -> some View {
        HStack(spacing: 6) {
            TextField("0", value: value, format: .number)
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

#if DEBUG
#Preview {
    DownloadsSettingsPane()
}
#endif
