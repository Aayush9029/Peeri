import Models
import Shared
import SwiftUI

struct TrackersSettingsPane: View {
    @Shared(.settings) private var settings

    var body: some View {
        SettingsForm {
            TrackerBlocklistsView()
            Section("Tracker Sources") {
                Toggle("Use only the trackers below", isOn: Binding($settings.advanced.onlyCustomTrackers))
                Text("Replace the trackers included in new torrents with your own list. DHT and peer exchange can still discover other peers.")
                    .settingDescription()
            }
            Section(settings.advanced.onlyCustomTrackers ? "Allowed Trackers" : "Additional Trackers") {
                trackerEditor("Tracker URLs", text: Binding($settings.advanced.trackers))
                Text("One HTTP, HTTPS, or UDP announce URL per line.")
                    .settingDescription()
                if settings.advanced.onlyCustomTrackers && settings.advanced.trackers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Label("Add a tracker to use tracker-based discovery.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange).font(.callout)
                }
            }
            if !settings.advanced.onlyCustomTrackers {
                Section("Excluded Trackers") {
                    trackerEditor("Excluded tracker URLs", text: Binding($settings.advanced.excludedTrackers))
                    Text("Exclude these exact announce URLs from new torrents and your additional trackers.")
                        .settingDescription()
                }
            }
            if !settings.advanced.invalidTrackerEntries.isEmpty {
                Label("Some tracker URLs are invalid and will be ignored.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange).font(.callout)
            }
            Text("These lists control trackers. Peer IP allow lists and block lists are not supported by aria2.")
                .settingDescription()
        }
    }

    private func trackerEditor(_ title: String, text: Binding<String>) -> some View {
        TextEditor(text: text)
            .font(.system(.callout, design: .monospaced))
            .scrollContentBackground(.hidden)
            .frame(minHeight: 100, maxHeight: 160)
            .accessibilityLabel(title)
            .overlay(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text("https://tracker.example/announce")
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }
}
