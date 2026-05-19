/*
 * Shir o Khorshid - iOS Psiphon Fork
 * Disguise mode settings - alternate app icons.
 */

import SwiftUI

struct DisguiseSettingsView: View {

    @ObservedObject var store: ShirSettingsStore
    @State private var iconChangeError: String?

    private let identities: [(id: String, title: String, iconName: String?, systemIcon: String)] = [
        ("default",
         NSLocalizedString("Shir o Khorshid", comment: "Disguise identity"),
         nil,
         "sun.max.fill"),
        ("calculator",
         NSLocalizedString("Calculator", comment: "Disguise identity"),
         "CalculatorIcon",
         "function"),
        ("weather",
         NSLocalizedString("Weather", comment: "Disguise identity"),
         "WeatherIcon",
         "cloud.sun.fill"),
        ("notes",
         NSLocalizedString("Notes", comment: "Disguise identity"),
         "NotesIcon",
         "note.text"),
        ("clock",
         NSLocalizedString("Clock", comment: "Disguise identity"),
         "ClockIcon",
         "clock.fill")
    ]

    var body: some View {
        List {
            Section {
                ForEach(identities, id: \.id) { identity in
                    Button {
                        changeIcon(to: identity)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: identity.systemIcon)
                                .font(.title2)
                                .frame(width: 36, height: 36)
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text(identity.title)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            if store.disguiseIdentity == identity.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }

                if let error = iconChangeError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } header: {
                Text(NSLocalizedString("App Appearance", comment: ""))
            } footer: {
                Text(NSLocalizedString("Change the app icon to disguise it. iOS will show a brief notification when the icon changes.", comment: ""))
            }

            Section {
                Toggle(isOn: $store.stealthNotifications) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Stealth Notifications", comment: ""))
                        Text(NSLocalizedString("Show disguise-appropriate notification content instead of VPN status", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: store.stealthNotifications) { _ in
                    store.notifySettingsChanged()
                }
            } header: {
                Text(NSLocalizedString("Notifications", comment: ""))
            } footer: {
                Text(NSLocalizedString("Note: The VPN indicator in the status bar cannot be hidden on iOS.", comment: ""))
            }
        }
        .navigationTitle(NSLocalizedString("Disguise Mode", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changeIcon(to identity: (id: String, title: String, iconName: String?, systemIcon: String)) {
        store.disguiseIdentity = identity.id

        guard UIApplication.shared.supportsAlternateIcons else {
            iconChangeError = NSLocalizedString("This device does not support alternate icons", comment: "")
            return
        }

        let iconName = identity.iconName // nil = default icon
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                iconChangeError = error.localizedDescription
            } else {
                iconChangeError = nil
            }
        }
    }
}
