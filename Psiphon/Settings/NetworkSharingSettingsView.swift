/*
 * Shir o Khorshid - iOS Psiphon Fork
 * LAN proxy sharing settings.
 */

import SwiftUI

struct NetworkSharingSettingsView: View {

    @ObservedObject var store: ShirSettingsStore
    @State private var showWarning = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { store.shareProxyOnNetwork },
                    set: { newValue in
                        if newValue {
                            showWarning = true
                        } else {
                            store.shareProxyOnNetwork = false
                            store.notifySettingsChanged()
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Share Proxy on Network", comment: ""))
                        Text(NSLocalizedString("Allow other devices on your WiFi to use this VPN connection", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(NSLocalizedString("LAN Proxy", comment: ""))
            } footer: {
                if store.shareProxyOnNetwork {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Other devices can connect using:", comment: ""))
                        Text("SOCKS5 / HTTP proxy")
                            .font(.system(.caption, design: .monospaced))
                        Text(NSLocalizedString("Configure the proxy address on other devices to use this connection.", comment: ""))
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Network Sharing", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .alert(NSLocalizedString("Security Warning", comment: ""),
               isPresented: $showWarning) {
            Button(NSLocalizedString("Enable", comment: ""), role: .destructive) {
                store.shareProxyOnNetwork = true
                store.notifySettingsChanged()
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("Sharing the proxy on your local network allows any device on the same WiFi network to route traffic through your VPN connection. Only enable this on trusted networks.", comment: ""))
        }
    }
}
