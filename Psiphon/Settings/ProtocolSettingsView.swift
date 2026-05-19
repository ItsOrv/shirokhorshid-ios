/*
 * Shir o Khorshid - iOS Psiphon Fork
 * Protocol selection and beast mode settings.
 */

import SwiftUI

struct ProtocolSettingsView: View {

    @ObservedObject var store: ShirSettingsStore

    private let protocols: [(id: String, title: String, description: String)] = [
        ("auto",
         NSLocalizedString("Auto", comment: "Protocol mode"),
         NSLocalizedString("Automatically selects the best protocol", comment: "")),
        ("conduit",
         NSLocalizedString("Conduit (InProxy)", comment: "Protocol mode"),
         NSLocalizedString("Connect via volunteer relay proxies", comment: "")),
        ("cdn_fronting",
         NSLocalizedString("CDN Fronting", comment: "Protocol mode"),
         NSLocalizedString("Use CDN domain fronting (FRONTED-MEEK-CDN-OSSH)", comment: "")),
        ("direct",
         NSLocalizedString("Direct", comment: "Protocol mode"),
         NSLocalizedString("Direct protocols: SSH, OSSH, TLS-OSSH, QUIC, Shadowsocks", comment: ""))
    ]

    var body: some View {
        List {
            Section {
                ForEach(protocols, id: \.id) { proto in
                    Button {
                        store.protocolSelection = proto.id
                        store.notifySettingsChanged()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(proto.title)
                                    .foregroundColor(.primary)
                                Text(proto.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if store.protocolSelection == proto.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text(NSLocalizedString("Protocol", comment: ""))
            }

            Section {
                Toggle(isOn: $store.beastMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                            Text(NSLocalizedString("Beast Mode", comment: ""))
                        }
                        Text(store.beastMode
                            ? NSLocalizedString("Aggressive: tries all protocols on every server", comment: "")
                            : NSLocalizedString("Normal: randomly selects protocols per server", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: store.beastMode) { [weak store] _ in
                    store?.notifySettingsChanged()
                }
            } header: {
                Text(NSLocalizedString("Establishment", comment: ""))
            }
        }
        .navigationTitle(NSLocalizedString("Protocol & Connection", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}
