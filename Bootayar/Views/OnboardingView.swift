import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 72, height: 72)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(BootayarTheme.brandGradient)
                            .frame(width: 64, height: 64)
                        Image(systemName: "power")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                Text("Welcome to Bootayar")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("macOS Startup & Automation Manager")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BootayarTheme.indigo)
                Text("Manage startup apps, background services, and scheduled tasks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FeatureCard(
                    icon: "list.bullet.rectangle",
                    title: "Manage Startup Tasks",
                    description: "View and manage tasks that start automatically, without using Terminal"
                )
                FeatureCard(
                    icon: "clock.badge.checkmark",
                    title: "Schedule Tasks",
                    description: "Run tasks at set times, at intervals, or when files change"
                )
                FeatureCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Edit Task Settings",
                    description: "Use a simple form or edit the configuration file directly"
                )
                FeatureCard(
                    icon: "bolt.fill",
                    title: "View Services and Ports",
                    description: "See local network ports, Homebrew services, and Docker containers"
                )
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(BootayarTheme.amber)
                    .font(.system(size: 13, weight: .semibold))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Before You Delete a Task")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(BootayarTheme.amber)
                    Text("Deleting a task configuration does not delete its app. Changes to system tasks may require an administrator password.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(BootayarTheme.amber.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(BootayarTheme.amber.opacity(0.28), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button("Get Started") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(30)
        .frame(width: 540)
        .background(BootayarTheme.subtleHeaderGradient)
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(BootayarTheme.indigo.opacity(0.14))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BootayarTheme.indigo)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(BootayarTheme.indigo.opacity(0.16), lineWidth: 1)
        )
    }
}
