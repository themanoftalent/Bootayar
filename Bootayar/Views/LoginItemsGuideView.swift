import AppKit
import ServiceManagement
import SwiftUI

enum LoginItemsSettings {
    static func openSystemSettings() {
        if #available(macOS 13.0, *) {
            SMAppService.openSystemSettingsLoginItems()
        } else if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct LoginItemsGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How Login Items Differ from Launchd")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Learn how macOS Login Items work below, then manage them in System Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                GuideCard(
                    icon: "gearshape.2.fill",
                    title: "Launchd (Managed by Bootayar)",
                    description: "Corresponds to LaunchAgents and LaunchDaemons in the sidebar (~/Library/LaunchAgents, /Library/LaunchAgents, /Library/LaunchDaemons). Load, unload, start, and stop them directly in Bootayar."
                )

                GuideCard(
                    icon: "key.fill",
                    title: "Login Items (Managed in System Settings)",
                    description: "Located in System Settings → General → Login Items, including Open at Login apps and Allow in the Background items. Managed directly by macOS."
                )

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(BootayarTheme.indigo)
                    Text("Many Login Items correspond to a launchd plist. If they appear under Launch Agents or LaunchDaemons, manage them right here in Bootayar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(BootayarTheme.indigo.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(BootayarTheme.indigo.opacity(0.20), lineWidth: 1)
                )

                Button {
                    LoginItemsSettings.openSystemSettings()
                } label: {
                    Label("Open Login Items Settings", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
            .frame(maxWidth: 580, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Login Items")
    }
}

private struct GuideCard: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(BootayarTheme.indigo.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BootayarTheme.indigo)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bootayarCard()
    }
}
