/*
 * Shir o Khorshid - iOS Psiphon Fork
 * Main SwiftUI settings hub.
 */

import SwiftUI

// MARK: - Settings Store (bridges NSUserDefaults to SwiftUI)

@objc final class ShirSettingsStore: NSObject, ObservableObject {

    private let defaults: UserDefaults

    init(appGroupIdentifier: String = "group.com.shirokhorshid.vpn") {
        let defs = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
        self.defaults = defs

        // Initialize all @Published properties BEFORE super.init()
        self.protocolSelection = defs.string(forKey: "shir_protocol_selection") ?? "auto"
        self.beastMode = defs.object(forKey: "shir_beast_mode") == nil ? true : defs.bool(forKey: "shir_beast_mode")
        self.cdnFrontingCustomIpList = defs.string(forKey: "shir_cdn_fronting_custom_ip_list") ?? ""
        self.cdnFrontingCustomSni = defs.string(forKey: "shir_cdn_fronting_custom_sni") ?? ""
        self.conduitMode = defs.string(forKey: "shir_conduit_mode") ?? "auto"
        let timeout = defs.integer(forKey: "shir_conduit_timeout_seconds")
        self.conduitTimeoutSeconds = timeout > 0 ? timeout : 180
        self.rejectCensoredCountryProxies = defs.object(forKey: "shir_reject_censored_country_proxies") == nil ? true : defs.bool(forKey: "shir_reject_censored_country_proxies")
        self.shareProxyOnNetwork = defs.bool(forKey: "shir_share_proxy_on_network")
        self.disguiseIdentity = defs.string(forKey: "shir_disguise_identity") ?? "default"
        self.stealthNotifications = defs.bool(forKey: "shir_stealth_notifications")

        super.init()
    }

    // MARK: - Protocol Selection

    @Published var protocolSelection: String {
        didSet { defaults.set(protocolSelection, forKey: "shir_protocol_selection") }
    }

    @Published var beastMode: Bool {
        didSet { defaults.set(beastMode, forKey: "shir_beast_mode") }
    }

    // MARK: - CDN Fronting

    @Published var cdnFrontingCustomIpList: String {
        didSet { defaults.set(cdnFrontingCustomIpList, forKey: "shir_cdn_fronting_custom_ip_list") }
    }

    @Published var cdnFrontingCustomSni: String {
        didSet { defaults.set(cdnFrontingCustomSni, forKey: "shir_cdn_fronting_custom_sni") }
    }

    // MARK: - Conduit

    @Published var conduitMode: String {
        didSet { defaults.set(conduitMode, forKey: "shir_conduit_mode") }
    }

    @Published var conduitTimeoutSeconds: Int {
        didSet { defaults.set(conduitTimeoutSeconds, forKey: "shir_conduit_timeout_seconds") }
    }

    @Published var rejectCensoredCountryProxies: Bool {
        didSet { defaults.set(rejectCensoredCountryProxies, forKey: "shir_reject_censored_country_proxies") }
    }

    // MARK: - Network

    @Published var shareProxyOnNetwork: Bool {
        didSet { defaults.set(shareProxyOnNetwork, forKey: "shir_share_proxy_on_network") }
    }

    // MARK: - Disguise

    @Published var disguiseIdentity: String {
        didSet { defaults.set(disguiseIdentity, forKey: "shir_disguise_identity") }
    }

    @Published var stealthNotifications: Bool {
        didSet { defaults.set(stealthNotifications, forKey: "shir_stealth_notifications") }
    }

    // Notify the extension that settings have changed
    func notifySettingsChanged() {
        let name = "com.shirokhorshid.vpn.settingsChanged" as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name),
            nil, nil, true
        )
    }

    // Reload values from defaults (e.g. after extension changes them)
    func reload() {
        protocolSelection = defaults.string(forKey: "shir_protocol_selection") ?? "auto"
        beastMode = defaults.object(forKey: "shir_beast_mode") == nil ? true : defaults.bool(forKey: "shir_beast_mode")
        cdnFrontingCustomIpList = defaults.string(forKey: "shir_cdn_fronting_custom_ip_list") ?? ""
        cdnFrontingCustomSni = defaults.string(forKey: "shir_cdn_fronting_custom_sni") ?? ""
        conduitMode = defaults.string(forKey: "shir_conduit_mode") ?? "auto"
        let timeout = defaults.integer(forKey: "shir_conduit_timeout_seconds")
        conduitTimeoutSeconds = timeout > 0 ? timeout : 180
        rejectCensoredCountryProxies = defaults.object(forKey: "shir_reject_censored_country_proxies") == nil ? true : defaults.bool(forKey: "shir_reject_censored_country_proxies")
        shareProxyOnNetwork = defaults.bool(forKey: "shir_share_proxy_on_network")
        disguiseIdentity = defaults.string(forKey: "shir_disguise_identity") ?? "default"
        stealthNotifications = defaults.bool(forKey: "shir_stealth_notifications")
    }
}

// MARK: - Main Settings View

struct ShirSettingsView: View {

    @ObservedObject var store: ShirSettingsStore

    var body: some View {
        NavigationView {
            List {
                // Protocol & Connection
                Section {
                    NavigationLink {
                        ProtocolSettingsView(store: store)
                    } label: {
                        HStack {
                            Image(systemName: "network")
                            Text(NSLocalizedString("Protocol & Connection", comment: ""))
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Connection", comment: ""))
                }

                // CDN Fronting (visible for auto, direct, cdn_fronting)
                if store.protocolSelection != "conduit" {
                    Section {
                        NavigationLink {
                            CdnFrontingSettingsView(store: store)
                        } label: {
                            HStack {
                                Image(systemName: "shield.lefthalf.filled")
                                Text(NSLocalizedString("CDN Fronting", comment: ""))
                            }
                        }
                    } header: {
                        Text(NSLocalizedString("Fronting", comment: ""))
                    }
                }

                // Conduit (visible for auto, conduit)
                if store.protocolSelection == "auto" || store.protocolSelection == "conduit" {
                    Section {
                        NavigationLink {
                            ConduitSettingsView(store: store)
                        } label: {
                            HStack {
                                Image(systemName: "point.3.connected.trianglepath.dotted")
                                Text(NSLocalizedString("Conduit / InProxy", comment: ""))
                            }
                        }
                    } header: {
                        Text(NSLocalizedString("Relay", comment: ""))
                    }
                }

                // Network Sharing
                Section {
                    NavigationLink {
                        NetworkSharingSettingsView(store: store)
                    } label: {
                        HStack {
                            Image(systemName: "wifi")
                            Text(NSLocalizedString("Network Sharing", comment: ""))
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Network", comment: ""))
                }

                // Disguise
                Section {
                    NavigationLink {
                        DisguiseSettingsView(store: store)
                    } label: {
                        HStack {
                            Image(systemName: "theatermasks")
                            Text(NSLocalizedString("Disguise Mode", comment: ""))
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Stealth", comment: ""))
                }
            }
            .navigationTitle(NSLocalizedString("Shir o Khorshid", comment: ""))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
