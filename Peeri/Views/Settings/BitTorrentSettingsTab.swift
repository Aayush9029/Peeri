import Models
import Shared
import SwiftUI

struct BitTorrentSettingsTab: View {
    @Shared(.settings) var settings

    var body: some View {
        Form {
            Section("Peer Discovery") {
                Toggle("Enable Local Peer Discovery (LPD)", isOn: Binding($settings.btEnableLPD))
                Toggle("Enable Peer Exchange (PEX)", isOn: Binding($settings.enablePeerExchange))
            }

            Section("Connection Limits") {
                HStack {
                    Text("Max Peers per Torrent")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", value: Binding($settings.btMaxPeers), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("(1-100)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Request Peer Speed Limit")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", text: Binding($settings.btRequestPeerSpeedLimit))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("(e.g., 50K, 1M)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    BitTorrentSettingsTab()
}
