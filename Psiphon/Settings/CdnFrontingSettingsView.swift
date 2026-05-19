/*
 * Shir o Khorshid - iOS Psiphon Fork
 * CDN Fronting custom IPs and SNI settings.
 */

import SwiftUI

struct CdnFrontingSettingsView: View {

    @ObservedObject var store: ShirSettingsStore
    @State private var ipValidationError: String?
    @State private var sniValidationError: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Custom CDN Edge IPs", comment: ""))
                        .font(.headline)
                    Text(NSLocalizedString("Enter up to 32 IPv4 addresses, one per line or comma-separated", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $store.cdnFrontingCustomIpList)
                        .frame(minHeight: 120)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: store.cdnFrontingCustomIpList) { newValue in
                            validateIPs(newValue)
                            store.notifySettingsChanged()
                        }
                    if let error = ipValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("Edge IP Addresses", comment: ""))
            } footer: {
                Text(NSLocalizedString("Built-in Akamai edge IPs (9) are always included. Your custom IPs are added in addition.", comment: ""))
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Custom SNI Hostname", comment: ""))
                        .font(.headline)
                    Text(NSLocalizedString("Optional: override the SNI server name for edge connections", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(NSLocalizedString("e.g. example.com", comment: ""), text: $store.cdnFrontingCustomSni)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .onChange(of: store.cdnFrontingCustomSni) { newValue in
                            validateSNI(newValue)
                            store.notifySettingsChanged()
                        }
                    if let error = sniValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("SNI Override", comment: ""))
            } footer: {
                Text(NSLocalizedString("If empty, the edge IP address itself is used as SNI.", comment: ""))
            }
        }
        .navigationTitle(NSLocalizedString("CDN Fronting", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func validateIPs(_ input: String) {
        guard !input.isEmpty else {
            ipValidationError = nil
            return
        }
        let entries = input.components(separatedBy: CharacterSet(charactersIn: " ,;\n\r\t"))
        var count = 0
        for entry in entries {
            let ip = entry.trimmingCharacters(in: .whitespaces)
            if ip.isEmpty { continue }
            count += 1
            if !Self.isValidIPv4(ip) {
                ipValidationError = String(format: NSLocalizedString("Invalid IP: %@", comment: ""), ip)
                return
            }
        }
        if count > 32 {
            ipValidationError = NSLocalizedString("Maximum 32 IPs allowed", comment: "")
            return
        }
        ipValidationError = nil
    }

    private func validateSNI(_ input: String) {
        guard !input.isEmpty else {
            sniValidationError = nil
            return
        }
        let sni = input.trimmingCharacters(in: .whitespaces)
        if Self.isValidIPv4(sni) {
            sniValidationError = NSLocalizedString("SNI must be a hostname, not an IP address", comment: "")
            return
        }
        if sni.count > 253 {
            sniValidationError = NSLocalizedString("Hostname too long (max 253 characters)", comment: "")
            return
        }
        var normalized = sni
        if normalized.hasSuffix(".") { normalized = String(normalized.dropLast()) }
        let labels = normalized.split(separator: ".", omittingEmptySubsequences: false)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        for label in labels {
            if label.isEmpty || label.count > 63 || label.hasPrefix("-") || label.hasSuffix("-") {
                sniValidationError = String(format: NSLocalizedString("Invalid label: %@", comment: ""), String(label))
                return
            }
            if !CharacterSet(charactersIn: String(label)).isSubset(of: allowed) {
                sniValidationError = String(format: NSLocalizedString("Invalid characters in: %@", comment: ""), String(label))
                return
            }
        }
        sniValidationError = nil
    }

    static func isValidIPv4(_ str: String) -> Bool {
        let parts = str.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let val = Int(part), val >= 0, val <= 255, part.count <= 3 else { return false }
            return true
        }
    }
}
