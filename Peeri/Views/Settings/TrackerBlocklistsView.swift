import Models
import Shared
import SwiftUI

struct TrackerBlocklistsView: View {
    @Shared(.settings) private var settings
    @Environment(TrackerBlocklistUpdater.self) private var updater

    private var lists: TrackerBlocklists { settings.advanced.trackerBlocklists ?? TrackerBlocklists() }

    var body: some View {
        Section("Community Blocklists") {
            ForEach(TrackerBlocklistCategory.allCases) { category in
                Toggle(isOn: Binding(
                    get: { lists.enabled.contains(category) },
                    set: { setEnabled($0, category: category) }
                )) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.title)
                        Text(category.detail).settingDescription()
                    }
                }
                .accessibilityLabel(category.title)
                .accessibilityHint(category.detail)
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    if updater.isUpdating {
                        Text("Updating blocklists…")
                    } else if let date = lists.updatedAt {
                        Text("\(lists.excludedURLs.count) tracker URLs excluded")
                        Text("Updated \(date.formatted(date: .abbreviated, time: .shortened))")
                            .settingDescription()
                    } else {
                        Text("Enable a list to download its tracker URLs.")
                            .settingDescription()
                    }
                }
                Spacer()
                Button("Update Now") { Task { await updater.update() } }
                    .disabled(updater.isUpdating || lists.enabled.isEmpty)
            }
            if let error = updater.error {
                Text(error).foregroundStyle(.red).font(.callout)
            }
            Text("Applies to new downloads, including your additional trackers. Enabled lists refresh daily when Peeri is open. Previously downloaded lists remain available offline.")
                .settingDescription()
            Link("Source: ngosang / trackerslist", destination: URL(string: "https://github.com/ngosang/trackerslist/blob/master/blacklist.txt")!)
                .font(.callout)
        }
        .task(id: lists.enabled) {
            await updater.refreshIfNeeded()
        }
    }

    private func setEnabled(_ enabled: Bool, category: TrackerBlocklistCategory) {
        $settings.withLock {
            var lists = $0.advanced.trackerBlocklists ?? TrackerBlocklists()
            if enabled { lists.enabled.insert(category) }
            else { lists.enabled.remove(category) }
            $0.advanced.trackerBlocklists = lists
        }
    }

}
