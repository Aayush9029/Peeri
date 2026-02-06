import Models
import Shared
import SwiftUI

struct BitTorrentSettingsTab: View {
    @Shared(.settings) var settings
    @State private var btEnableLPD: Bool
    @State private var enablePeerExchange: Bool
    @State private var btMaxPeers: Int
    @State private var btRequestPeerSpeedLimit: String

    init() {
        let settings = Shared(.settings).wrappedValue
        _btEnableLPD = State(initialValue: settings.btEnableLPD)
        _enablePeerExchange = State(initialValue: settings.enablePeerExchange)
        _btMaxPeers = State(initialValue: settings.btMaxPeers)
        _btRequestPeerSpeedLimit = State(initialValue: settings.btRequestPeerSpeedLimit)
    }

    var body: some View {
        Form {
            Section("Peer Discovery") {
                Toggle("Enable Local Peer Discovery (LPD)", isOn: $btEnableLPD)
                Toggle("Enable Peer Exchange (PEX)", isOn: $enablePeerExchange)
            }

            Section("Connection Limits") {
                HStack {
                    Text("Max Peers per Torrent")
                        .frame(width: 180, alignment: .leading)
                    Spacer()
                    TextField("", value: $btMaxPeers, format: .number)
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
                    TextField("", text: $btRequestPeerSpeedLimit)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("(e.g., 50K, 1M)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: btEnableLPD) { _, newValue in
            $settings.withLock { $0.btEnableLPD = newValue }
        }
        .onChange(of: enablePeerExchange) { _, newValue in
            $settings.withLock { $0.enablePeerExchange = newValue }
        }
        .onChange(of: btMaxPeers) { _, newValue in
            $settings.withLock { $0.btMaxPeers = newValue }
        }
        .onChange(of: btRequestPeerSpeedLimit) { _, newValue in
            $settings.withLock { $0.btRequestPeerSpeedLimit = newValue }
        }
    }
}

#Preview {
    BitTorrentSettingsTab()
}
