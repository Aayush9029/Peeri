import Models
import Shared
import SwiftUI

struct VideoSettingsPane: View {
    @Shared(.settings) private var settings
    @State private var versionStatus: VersionStatus = .checking

    var body: some View {
        SettingsForm {
            Section("Video Downloads") {
                LabeledContent("Downloader version") {
                    versionLabel
                }

                Button("Check Version") {
                    Task { await refreshVersion() }
                }

                Text("Download videos from YouTube and Vimeo.")
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
        case .best: "Best quality"
        case .mp4: "Prefer MP4"
        case .audioOnly: "Audio only"
        }
    }

    var description: String {
        switch self {
        case .best:
            "Download the best available video and audio, combined into one file."
        case .mp4:
            "Choose MP4 when available, or the next best format."
        case .audioOnly:
            "Downloads the best available audio stream."
        }
    }
}
