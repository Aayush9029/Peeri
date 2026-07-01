import Models
import Shared
import SwiftUI

struct VideoSettingsPane: View {
    @Shared(.settings) private var settings
    @State private var versionStatus: VersionStatus = .checking

    var body: some View {
        Form {
            Section("yt-dlp") {
                LabeledContent("Status") {
                    versionLabel
                }

                Button("Check Version") {
                    Task { await refreshVersion() }
                }

                Text("Peeri uses the bundled yt-dlp executable for YouTube and other supported video links.")
                    .settingDescription()
            }

            Section("Format") {
                Picker("Download", selection: Binding($settings.videoFormatPreference)) {
                    ForEach(VideoFormatPreference.allCases) { preference in
                        Text(preference.title).tag(preference)
                    }
                }
                Text(settings.videoFormatPreference.description)
                    .settingDescription()
            }
        }
        .formStyle(.grouped)
        .task {
            await refreshVersion()
        }
    }

    @ViewBuilder
    private var versionLabel: some View {
        switch versionStatus {
        case .checking:
            ProgressView()
                .controlSize(.small)
        case let .available(version):
            Label(version, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case let .failed(message):
            Label(message, systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private func refreshVersion() async {
        versionStatus = .checking
        do {
            versionStatus = .available(try await YTDLPClient().version())
        } catch {
            versionStatus = .failed(error.localizedDescription)
        }
    }
}

private enum VersionStatus: Equatable {
    case checking
    case available(String)
    case failed(String)
}

private extension VideoFormatPreference {
    var title: String {
        switch self {
        case .best: "Best single file"
        case .mp4: "Prefer MP4"
        case .audioOnly: "Audio only"
        }
    }

    var description: String {
        switch self {
        case .best:
            "Downloads the best single-file format yt-dlp can find without requiring a separate merge step."
        case .mp4:
            "Prefers MP4 when available, then falls back to the best single-file format."
        case .audioOnly:
            "Downloads the best available audio stream."
        }
    }
}

#if DEBUG
#Preview {
    VideoSettingsPane()
}
#endif
