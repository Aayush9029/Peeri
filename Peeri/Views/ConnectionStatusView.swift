import SwiftUI

struct ConnectionStatusView: View {
    let state: ConnectionState

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .help(tooltip)
    }

    private var color: Color {
        switch state {
        case .connected: .green
        case .connecting: .orange
        case .disconnected, .failed: .red
        }
    }

    private var tooltip: String {
        switch state {
        case .connected: "Connected to aria2"
        case .connecting: "Connecting…"
        case .disconnected: "Disconnected"
        case .failed(let error): "Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        ConnectionStatusView(state: .connected)
        ConnectionStatusView(state: .connecting)
        ConnectionStatusView(state: .disconnected)
    }
    .padding()
}
