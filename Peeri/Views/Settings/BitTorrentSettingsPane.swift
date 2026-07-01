import Models
import Shared
import SwiftUI

struct BitTorrentSettingsPane: View {
    @Shared(.settings) private var settings

    var body: some View {
        Form {
            Section("Peer Discovery") {
                Toggle("Enable local peer discovery", isOn: Binding($settings.btEnableLPD))
                Toggle("Enable peer exchange", isOn: Binding($settings.enablePeerExchange))
            }

            Section("Connection Limits") {
                Stepper(value: Binding($settings.btMaxPeers), in: 1 ... 100) {
                    LabeledContent("Max Peers per Torrent", value: "\(settings.btMaxPeers)")
                }

                LabeledContent("Request Peer Speed Limit") {
                    TextField("100K", text: Binding($settings.btRequestPeerSpeedLimit))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                Text("Use aria2 size notation, for example 100K or 1M.")
                    .settingDescription()
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    BitTorrentSettingsPane()
}
