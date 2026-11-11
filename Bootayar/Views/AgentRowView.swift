import SwiftUI

struct AgentRowView: View {
    let item: LaunchItem
    let brewService: HomebrewService?
    let brewPending: PendingOperation?
    let brewActions: BrewRowActions?
    @ObservedObject var store: AgentStore
    @Binding var errorMessage: String?

    @State private var isExpanded = false
    @State private var showingEdit = false
    @State private var showingClone = false
    @State private var showingLog  = false
    @State private var showingDeleteConfirm = false

    private var usesBrewOperations: Bool {
        item.isBrewManaged && brewService != nil && brewActions != nil
    }

    private var pending: PendingOperation? {
        brewPending ?? store.pendingOperations[item.label]
    }

    private var isRowLocked: Bool {
        pending != nil
    }

    var statusColor: Color {
        if pending != nil { return BootayarTheme.amber }
        if usesBrewOperations, let brewService {
            switch brewService.status {
            case .started:
                return item.pid != nil ? BootayarTheme.emerald : BootayarTheme.amber
            case .stopped:
                if item.pid != nil { return BootayarTheme.amber }
                return BootayarTheme.amber
            case .error: return BootayarTheme.crimson
            case .none: return BootayarTheme.neutralSlate
            case .unknown: return BootayarTheme.amber
            }
        }
        if item.isDisabledByOverride && item.pid == nil { return BootayarTheme.amber }
        if item.pid != nil { return BootayarTheme.emerald }
        if let code = item.lastExitCode {
            if code == 0  { return BootayarTheme.loadedIndigo }
            if code > 0   { return BootayarTheme.amber }
        }
        if item.isLoaded { return BootayarTheme.loadedIndigo }
        return BootayarTheme.neutralSlate
    }

    private var statusBadgeTitle: LocalizedStringKey {
        if let pending { return pending.localizedLabel }
        if usesBrewOperations, let brewService {
            switch brewService.status {
            case .started: return item.pid != nil ? "Running" : "Starting"
            case .stopped: return item.pid != nil ? "Orphaned" : "Stopped"
            case .error: return "Error"
            case .none: return "Unregistered"
            case .unknown: return "Unknown"
            }
        }
        if item.isDisabledByOverride && item.pid == nil { return "Disabled" }
        if item.pid != nil { return "Running" }
        if let code = item.lastExitCode, code > 0 { return "Exit \(code)" }
        if item.isLoaded { return "Loaded" }
        return "Unloaded"
    }

    private var statusTooltip: String {
        if item.isDisabledByOverride {
            return String(localized: "Disabled by system (launchctl override)")
        }
        if usesBrewOperations, let brewService {
            if let exitCode = brewService.exitCode, brewService.status == .error {
                return String(localized: "Homebrew: \(brewService.status.localizedName) (exit code \(exitCode))")
            }
            if brewService.status == .stopped, item.pid != nil {
                return String(localized: "Brew stopped, but process is still running (PID \(item.pid!))")
            }
            if brewService.status == .started, item.pid == nil {
                return String(localized: "Brew: started, waiting for process")
            }
            return "Homebrew: \(brewService.status.localizedName)"
        }
        if let pid = item.pid { return String(localized: "Running (PID \(pid))") }
        if let code = item.lastExitCode {
            if code == 0  { return String(localized: "Last run: exited normally (0)") }
            if code < 0   { return String(localized: "Stopped (signal \(-code))") }
            return String(localized: "Last run: exit code \(code)")
        }
        return String(localized: item.isLoaded ? "Loaded, waiting for trigger" : "Not loaded")
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

                if item.isBrewManaged {
                    HomebrewTag()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let firstTrigger = item.triggerSummaryLines.first {
                        Text(LocalizedStringKey(firstTrigger))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let pid = item.pid {
                    Text("PID \(pid)")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(BootayarTheme.emerald)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(BootayarTheme.emerald.opacity(0.10)))
                }

                primaryActionButton

                HStack(spacing: 4) {
                    Button { showingEdit = true } label: {
                        Image(systemName: "pencil")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .disabled(isRowLocked)
                    .help("Edit")

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .disabled(isRowLocked)
                    .help("Delete")

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
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if isExpanded {
                Divider()
                    .opacity(0.6)
                VStack(alignment: .leading, spacing: 6) {
                    if let formula = item.brewFormulaName {
                        detailRow("Formula", formula)
                    }
                    if usesBrewOperations, let brewService {
                        detailRow("Managed By", String(localized: "brew services"))
                        detailRow("Brew Status", brewService.status.localizedName)
                        if let exitCode = brewService.exitCode {
                            detailRow("Exit Code", "\(exitCode)")
                        }
                        if let user = brewService.runAsUser {
                            detailRow("User", user)
                        }
                    }
                    detailRow("Program", FilePathNormalizer.display(([item.program] + item.programArguments).joined(separator: " ")))
                    detailRow("Trigger", triggerDescription)
                    detailRow("Path", FilePathNormalizer.display(item.plistURL.path))
                    HStack(spacing: 8) {
                        if usesBrewOperations, let brewService, let brewActions {
                            if brewService.isRunning {
                                Button("Restart") {
                                    brewActions.onRestart(brewService)
                                }
                                .buttonStyle(.bordered).controlSize(.small)
                                .disabled(isRowLocked)
                            }
                        } else if item.isLoaded {
                            Button("Unload") {
                                store.bootout(item) { errorMessage = $0 }
                            }
                            .buttonStyle(.bordered).controlSize(.small)
                            .disabled(isRowLocked)
                        }
                        Button("Clone…") { showingClone = true }
                            .buttonStyle(.bordered).controlSize(.small)
                            .disabled(isRowLocked)
                        Button("View Logs") { showingLog = true }
                            .buttonStyle(.bordered).controlSize(.small)
                            .disabled(isRowLocked)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(BootayarTheme.indigo.opacity(0.04))
            }
        }
        .bootayarCard(statusColor: statusColor, isExpanded: isExpanded)
        .sheet(isPresented: $showingEdit) {
            EditAgentSheet(existingItem: item, defaultScope: item.scope, store: store)
        }
        .sheet(isPresented: $showingClone) {
            CloneAgentSheet(item: item, store: store, errorMessage: $errorMessage)
        }
        .sheet(isPresented: $showingLog) {
            LogViewerSheet(item: item)
        }
        .confirmationDialog(
            String(localized: "Delete \(item.label)?"),
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                do { try store.delete(item) }
                catch { errorMessage = error.localizedDescription }
            }
        } message: {
            Text("This will unload and permanently delete the plist file. This cannot be undone.")
        }
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
        } else if usesBrewOperations, let brewService, let brewActions {
            if brewService.isRunning {
                Button("Stop") {
                    brewActions.onStop(brewService)
                }
                .buttonStyle(.borderedProminent).controlSize(.small)
            } else {
                Button("Start") {
                    brewActions.onStart(brewService)
                }
                .buttonStyle(.bordered).controlSize(.small)
            }
        } else if item.pid != nil {
            Button("Stop") {
                store.stop(item) { errorMessage = $0 }
            }
            .buttonStyle(.borderedProminent).controlSize(.small)
        } else if item.isDisabledByOverride && !item.isLoaded {
            Button("Enable") {
                store.enable(item) { errorMessage = $0 }
            }
            .buttonStyle(.borderedProminent).controlSize(.small)
        } else if item.isLoaded {
            Button("Start") {
                store.start(item) { errorMessage = $0 }
            }
            .buttonStyle(.bordered).controlSize(.small)
        } else {
            Button("Load") {
                store.bootstrap(item) { errorMessage = $0 }
            }
            .buttonStyle(.bordered).controlSize(.small)
        }
    }

    private func detailRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .leading)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .font(.caption)
    }

    private var triggerDescription: String {
        item.triggerSummaryLines.joined(separator: "\n")
    }
}
