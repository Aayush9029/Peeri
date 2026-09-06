import Models
import Shared
import SwiftUI

struct NetworkSettingsPane: View {
    @Shared(.settings) private var settings
    @State private var proxyText = ""
    @FocusState private var isProxyFocused: Bool

    var body: some View {
        SettingsForm {
            Section("Connections") {
                Toggle("Use IPv6", isOn: Binding($settings.advanced.enableIPv6))
                SettingsNumberRow("Incoming peer port", value: Binding($settings.advanced.listenPort), range: 1024...65535)
                Text("IPv6 and incoming port changes require restarting Peeri.")
                    .settingDescription()
                Toggle("Reuse web connections", isOn: Binding($settings.advanced.reuseConnections))
                Toggle("Use passive FTP", isOn: Binding($settings.advanced.ftpPassive))
            }
            Section("Retries & Timeouts") {
                SettingsNumberRow("Maximum attempts", value: Binding($settings.advanced.maxTries), range: 0...100)
                SettingsNumberRow("Wait between retries", value: Binding($settings.advanced.retryWait), range: 0...600, unit: "sec")
                SettingsNumberRow("Connection timeout", value: Binding($settings.advanced.connectTimeout), range: 1...600, unit: "sec")
                SettingsNumberRow("Inactivity timeout", value: Binding($settings.advanced.timeout), range: 1...600, unit: "sec")
                Text("Applies to new web and FTP downloads. Set maximum attempts to 0 to retry indefinitely.")
                    .settingDescription()
            }
            Section("Proxy") {
                TextField("HTTP proxy", text: $proxyText, prompt: Text("http://host:port"))
                    .focused($isProxyFocused)
                    .onSubmit { saveProxy() }
                    .onChange(of: isProxyFocused) { _, focused in
                        if !focused { saveProxy() }
                    }
                if Aria2Preferences.normalizedProxy(proxyText) == nil {
                    Text("Enter an HTTP proxy address, such as http://localhost:8080. Your previous proxy stays in use until this is corrected.")
                        .foregroundStyle(.orange).settingDescription()
                }
                TextField("Bypass proxy for", text: Binding($settings.advanced.proxyBypass), prompt: Text("localhost, example.com"))
                Text("Route web and FTP downloads through an HTTP proxy. Torrent peer traffic does not use this proxy.")
                    .settingDescription()
            }
            Section("Web Requests") {
                TextField("User agent", text: Binding($settings.advanced.userAgent), prompt: Text("Default"))
            }
        }
        .onAppear { proxyText = settings.advanced.proxy }
    }

    private func saveProxy() {
        guard let proxy = Aria2Preferences.normalizedProxy(proxyText) else { return }
        $settings.withLock { $0.advanced.proxy = proxy }
    }
}
