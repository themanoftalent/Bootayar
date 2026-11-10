import SwiftUI

struct HomebrewServiceRowView: View {
    let service: HomebrewService
    @ObservedObject var store: HomebrewServiceStore
    @Binding var errorMessage: String?
    var startButtonTitle: LocalizedStringKey = "Start"

    @State private var isExpanded = false

    private var pending: PendingOperation? {
        store.pendingOperations[service.id]
    }

    private var isRowLocked: Bool {
        pending != nil
    }

    private var statusColor: Color {
        if pending != nil { return BootayarTheme.amber }
        switch service.status {
        case .started: return BootayarTheme.emerald
        case .stopped: return BootayarTheme.amber
        case .error: return BootayarTheme.crimson
        case .none: return BootayarTheme.neutralSlate
        case .unknown: return BootayarTheme.amber
        }
    }

    private var statusBadgeTitle: LocalizedStringKey {
        if let pending { return pending.localizedLabel }
        switch service.status {
        case .started: return "Running"
        case .stopped: return "Stopped"
        case .error: return "Error"
        case .none: return "Unregistered"
        case .unknown: return "Unknown"
        }
    }

    private var statusTooltip: String {
        if let exitCode = service.exitCode, service.status == .error {
            return String(localized: "\(service.status.localizedName) (exit code \(exitCode))")
        }
        return service.status.localizedName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                BootayarStatusBadge(
                    title: statusBadgeTitle,
                    color: statusColor,
                    isPulsing: isRowLocked
                )
                .help(Text(statusTooltip))

                HomebrewTag()

                Text(service.name)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .lineLimit(1)

                Spacer()

                primaryActionButton

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .disabled(isRowLocked)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if isExpanded {
                Divider()
                    .opacity(0.6)
                VStack(alignment: .leading, spacing: 6) {
                    detailRow("Status", service.status.localizedName)
                    detailRow("Label", service.label)
                    if let user = service.runAsUser {
                        detailRow("User", user)
                    }
                    if let path = service.plistPath {
                        detailRow("Plist", FilePathNormalizer.display(path))
                    }
                    if service.scope.requiresPrivilege {
                        detailRow("Privilege", String(localized: "Administrator password required to start/stop"))
                    }
                    HStack(spacing: 8) {
                        if service.isRunning {
                            Button("Restart") {
                                store.restart(service) { errorMessage = $0 }
                            }
                            .buttonStyle(.bordered).controlSize(.small)
                            .disabled(isRowLocked)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(BootayarTheme.indigo.opacity(0.04))
            }
        }
        .bootayarCard(statusColor: statusColor, isExpanded: isExpanded)
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        if let pending {
            Button {} label: {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(pending.localizedLabel)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(true)
        } else if service.isRunning {
            Button("Stop") {
                store.stop(service) { errorMessage = $0 }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        } else {
            Button(startButtonTitle) {
                store.start(service) { errorMessage = $0 }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func detailRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .font(.caption)
    }
}
