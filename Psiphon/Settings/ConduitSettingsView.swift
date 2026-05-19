/*
 * Shir o Khorshid - iOS Psiphon Fork
 * Conduit / InProxy settings.
 */

import SwiftUI

struct ConduitSettingsView: View {

    @ObservedObject var store: ShirSettingsStore

    private let conduitModes: [(id: String, title: String, description: String)] = [
        ("auto",
         NSLocalizedString("Auto (Recommended)", comment: "Conduit mode"),
         NSLocalizedString("Tries Shir o Khorshid conduits first, falls back to public after timeout", comment: "")),
        ("shirokhorshid",
         NSLocalizedString("Shir o Khorshid Only", comment: "Conduit mode"),
         NSLocalizedString("Only connect via Shir o Khorshid volunteer relays", comment: "")),
        ("public",
         NSLocalizedString("Public Conduits", comment: "Conduit mode"),
         NSLocalizedString("Use any public InProxy-compatible relay", comment: ""))
    ]

    private let timeoutOptions: [(seconds: Int, label: String)] = [
        (120, NSLocalizedString("2 minutes", comment: "")),
        (180, NSLocalizedString("3 minutes (default)", comment: "")),
        (300, NSLocalizedString("5 minutes", comment: "")),
        (600, NSLocalizedString("10 minutes", comment: ""))
    ]

    var body: some View {
        List {
            Section {
                ForEach(conduitModes, id: \.id) { mode in
                    Button {
                        store.conduitMode = mode.id
                        store.notifySettingsChanged()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.title)
                                    .foregroundColor(.primary)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if store.conduitMode == mode.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text(NSLocalizedString("Conduit Mode", comment: ""))
            }

            // Timeout only visible in auto mode
            if store.conduitMode == "auto" {
                Section {
                    ForEach(timeoutOptions, id: \.seconds) { option in
                        Button {
                            store.conduitTimeoutSeconds = option.seconds
                            store.notifySettingsChanged()
                        } label: {
                            HStack {
                                Text(option.label)
                                    .foregroundColor(.primary)
                                Spacer()
                                if store.conduitTimeoutSeconds == option.seconds {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Fallback Timeout", comment: ""))
                } footer: {
                    Text(NSLocalizedString("Time to wait for Shir o Khorshid conduits before falling back to public relays", comment: ""))
                }
            }

            Section {
                Toggle(isOn: $store.rejectCensoredCountryProxies) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Reject Censored Country Proxies", comment: ""))
                        Text(NSLocalizedString("Block relays from Iran, China, Russia, Belarus, Turkmenistan, North Korea", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: store.rejectCensoredCountryProxies) { _ in
                    store.notifySettingsChanged()
                }
            } header: {
                Text(NSLocalizedString("Security", comment: ""))
            }
        }
        .navigationTitle(NSLocalizedString("Conduit / InProxy", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}
