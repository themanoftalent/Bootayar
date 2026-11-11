import AppKit
import SwiftUI

struct UpdateAvailableSheet: View {
    let release: GitHubRelease
    let currentVersion: AppVersion
    let onSkip: () -> Void
    let onDismiss: () -> Void

    @State private var copyConfirmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Update Available"))
                    .font(.title2)
                    .fontWeight(.bold)
                Text(L("Bootayar \(release.version.displayString) is now available"))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                versionColumn("Current Version", currentVersion.displayString)
                versionColumn("Latest Version", release.version.displayString)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(L("Direct Download"))
                    .font(.headline)
                Button {
                    NSWorkspace.shared.open(release.downloadURL)
                } label: {
                    Label(L("Download Bootayar.dmg"), systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L("Upgrade via Homebrew"))
                    .font(.headline)
                Text(GitHubRelease.homebrewUpgradeCommand)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Button(copyConfirmed ? "Copied" : "Copy Command") {
                    copyHomebrewCommand()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(copyConfirmed)
            }

            Link(destination: release.releasePageURL) {
                Label(L("View Release on GitHub"), systemImage: "link")
                    .font(.subheadline)
            }

            HStack {
                Button(L("Skip This Version"), role: .destructive) {
                    onSkip()
                }
                .buttonStyle(.borderless)
                Spacer()
                Button(L("Later")) {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    private func versionColumn(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospaced())
                .fontWeight(.semibold)
                .foregroundStyle(BootayarTheme.indigo)
        }
    }

    private func copyHomebrewCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(GitHubRelease.homebrewUpgradeCommand, forType: .string)
        copyConfirmed = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            copyConfirmed = false
        }
    }
}
