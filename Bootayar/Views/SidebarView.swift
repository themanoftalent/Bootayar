import AppKit
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSelection?
    @ObservedObject var moduleSettings: ModuleSettingsStore
    @ObservedObject var store: AgentStore
    @ObservedObject var crontabStore: CrontabStore
    @ObservedObject var serviceStore: ServiceStore
    @Binding var showModuleSettings: Bool
    var onHelpTapped: () -> Void

    private var agentCount: Int {
        store.items.count + store.invalidItems.count
    }

    private var runningAgentCount: Int {
        store.items.filter { $0.pid != nil }.count
    }

    private var loadedAgentCount: Int {
        store.items.filter { $0.isLoaded }.count
    }

    private var enabledModules: [AppModule] {
        moduleSettings.settings.enabledModules
    }

    var body: some View {
        VStack(spacing: 0) {
            brandHeader
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(BootayarTheme.subtleHeaderGradient)

            Divider()
                .opacity(0.5)

            List {
                Section {
                    ForEach(enabledModules) { module in
                        SidebarRowButton(
                            selection: $selection,
                            tag: module.sidebarSelection,
                            title: Text(module.title),
                            subtitle: Text(module.subtitle),
                            icon: module.systemImage,
                            badge: badge(for: module)
                        )
                    }
                } header: {
                    Text("YOUR TOOLS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(BootayarTheme.softViolet)
                        .tracking(0.8)
                }

                Section {
                    Button {
                        onHelpTapped()
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(BootayarTheme.electricViolet.opacity(0.14))
                                    .frame(width: 26, height: 26)
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(BootayarTheme.electricViolet)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("User Guide")
                                    .font(.system(size: 13, weight: .medium))
                                Text("github.com/themanoftalent/Bootayar")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    SidebarRowButton(
                        selection: $selection,
                        tag: .about,
                        title: Text("About Bootayar"),
                        subtitle: Text("Developer & support"),
                        icon: "info.circle.fill",
                        badge: 0
                    )
                } header: {
                    Text("HELP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Bootayar")

            Divider()
                .opacity(0.6)

            HStack(spacing: 10) {
                Button {
                    showModuleSettings = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BootayarTheme.indigo)
                        Text("Choose Tools")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(BootayarTheme.indigo.opacity(0.10))
                    )
                }
                .buttonStyle(.plain)
                .help("Choose which tools appear in the sidebar")

                Spacer()

                Button {
                    selection = .about
                } label: {
                    Text(AppVersion.current.displayString)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(BootayarTheme.softViolet)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule()
                                .fill(BootayarTheme.electricViolet.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .help("About Bootayar")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    private var brandHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 34, height: 34)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(BootayarTheme.brandGradient)
                            .frame(width: 32, height: 32)
                        Image(systemName: "power")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Bootayar")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("macOS Startup & Automation Manager")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            HStack(spacing: 6) {
                statusPill(
                    dotColor: BootayarTheme.emerald,
                    label: "Running",
                    value: "\(runningAgentCount)"
                )
                statusPill(
                    dotColor: BootayarTheme.loadedIndigo,
                    label: "Loaded",
                    value: "\(loadedAgentCount)"
                )
                if moduleSettings.isEnabled(.services) {
                    statusPill(
                        dotColor: BootayarTheme.electricViolet,
                        label: "Ports",
                        value: "\(serviceStore.services.count)"
                    )
                }
            }
        }
    }

    private func statusPill(dotColor: Color, label: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3.5)
        .background(
            Capsule()
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.85))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.8)
        )
    }

    private func badge(for module: AppModule) -> Int {
        switch module {
        case .agents: return agentCount
        case .crontab: return crontabStore.jobs.count
        case .services: return serviceStore.services.count
        case .loginItems: return 0
        }
    }
}

private struct SidebarRowButton: View {
    @Binding var selection: SidebarSelection?
    let tag: SidebarSelection
    let title: Text
    let subtitle: Text
    let icon: String
    let badge: Int

    private var isSelected: Bool { selection == tag }

    var body: some View {
        Button {
            selection = tag
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            isSelected
                                ? Color.white.opacity(0.22)
                                : BootayarTheme.indigo.opacity(0.12)
                        )
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : BootayarTheme.indigo)
                }

                VStack(alignment: .leading, spacing: 1) {
                    title
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? .white : .primary)
                    subtitle
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                if badge > 0 {
                    Text(verbatim: "\(badge)")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(isSelected ? .white : BootayarTheme.indigo)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(
                                    isSelected
                                        ? Color.white.opacity(0.22)
                                        : BootayarTheme.indigo.opacity(0.12)
                                )
                        )
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(BootayarTheme.sidebarSelectionGradient)
                        .padding(.vertical, 1)
                } else {
                    Color.clear
                }
            }
        )
    }
}
