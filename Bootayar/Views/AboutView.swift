import AppKit
import SwiftUI

struct AboutView: View {
    @ObservedObject var updateChecker: UpdateChecker
    var isInline: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BootayarTheme.brandGradient)
                            .frame(width: 68, height: 68)
                        Image(systemName: "power")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(spacing: 3) {
                    Text("Bootayar")
                        .font(.system(size: 20, weight: .bold))
                    Text("Version \(appVersion)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Text("Manage startup apps, background services, and scheduled tasks.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 4)

            OpenSourceCard()
            FollowSupportCard()

            HStack(spacing: 12) {
                Button {
                    updateChecker.checkNow()
                } label: {
                    if updateChecker.isChecking {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Check for Updates…")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(updateChecker.isChecking)

                if !isInline {
                    Spacer()

                    Button("Close") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
            .padding(.top, 2)
        }
        .padding(isInline ? 28 : 18)
        .frame(width: isInline ? 480 : 450)
        .frame(maxWidth: isInline ? .infinity : nil, maxHeight: isInline ? .infinity : nil)
    }

    private var appVersion: String {
        AppVersion.current.displayString
    }
}

private struct OpenSourceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .frame(width: 24, height: 24)
                    Text("{}")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                Text("Open Source | Free to Fork & Use")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text("Feel free to fork, modify, use, and contribute!")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Developed by:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("SoftAI Yazılım")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }
                HStack(spacing: 6) {
                    Text("Developer:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("Assoc. Prof. Dr. Mehmet Akif Cifci")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }
                HStack(spacing: 6) {
                    Text("GitHub:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Link("@themanoftalent", destination: URL(string: "https://github.com/themanoftalent")!)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct FollowSupportCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("❤️")
                    .font(.system(size: 16))
                Text("Follow & Support")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text("If you find this project useful, star the repository, follow me, or buy me a coffee! Your support helps keep future projects free and open-source.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Link(destination: URL(string: "https://github.com/themanoftalent/Bootayar")!) {
                    HStack(spacing: 6) {
                        Text("</>")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                        Text("GitHub")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.4), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Link(destination: URL(string: "https://github.com/sponsors/themanoftalent")!) {
                    HStack(spacing: 6) {
                        Text("❤️")
                            .font(.system(size: 12))
                        Text("Sponsor Me")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Link(destination: URL(string: "https://buymeacoffee.com/themanoftalent")!) {
                    HStack(spacing: 6) {
                        Text("☕")
                            .font(.system(size: 12))
                        Text("Buy Me a Coffee")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
