import Models
import Shared
import SwiftUI

struct BitTorrentSettingsPane: View {
    @Shared(.settings) private var settings

    var body: some View {
        SettingsForm {
            Section("Downloading") {
                Toggle("Prioritize file previews", isOn: Binding($settings.advanced.prioritizePreview))
                Text("Download the beginning and end of torrent files first. This helps some media players preview unfinished files.")
                    .settingDescription()
            }
            Section("Seeding") {
                Toggle("Seed completed torrents", isOn: Binding($settings.seedingEnabled))
                SettingsNumberRow("Time limit", value: Binding($settings.seedTimeMinutes), range: 1...10080, unit: "min")
                    .disabled(!settings.seedingEnabled)
                HStack {
                    Text("Share ratio")
                    Spacer()
                    TextField("Share ratio", value: Binding($settings.seedRatio), format: .number.precision(.fractionLength(0...2)))
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                .disabled(!settings.seedingEnabled)
                Toggle("Keep seeding outside the download queue", isOn: Binding($settings.advanced.seedOutsideQueue))
                Text("Stop at the time or ratio limit, whichever comes first. A ratio of 0 removes the ratio limit. Seeding limits also apply to current torrents.")
                    .settingDescription()
            }
            Section("Peer Discovery") {
                Toggle("Distributed hash table (DHT)", isOn: Binding($settings.advanced.enableDHT))
                Toggle("DHT over IPv6", isOn: Binding($settings.advanced.enableDHT6))
                    .disabled(!settings.advanced.enableIPv6)
                Toggle("Local network discovery", isOn: Binding($settings.btEnableLPD))
                Toggle("Peer exchange", isOn: Binding($settings.enablePeerExchange))
                Text("Find peers through the distributed network, nearby devices, and connected peers. DHT and local discovery changes require restarting Peeri.")
                    .settingDescription()
            }
            Section("Peer Connections") {
                Toggle("Require encrypted connections", isOn: Binding($settings.advanced.requireEncryption))
                SettingsNumberRow("Maximum peers per torrent", value: Binding($settings.btMaxPeers), range: 0...500)
                SettingsNumberRow("Target download speed", value: Binding($settings.peerTargetSpeedKB), range: 0...1000000, unit: "KB/s")
                Text("If a torrent falls below the target speed, try connecting to more peers. Set the target to 0 to turn this off. A peer limit of 0 allows unlimited peers.")
                    .settingDescription()
            }
            Text("Download and connection preferences apply to new torrents.")
                .settingDescription()
        }
    }
}
