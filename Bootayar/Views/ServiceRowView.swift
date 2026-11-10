import AppKit
import SwiftUI

struct ServiceRowView: View {
    let service: Service
    @ObservedObject var store: ServiceStore
    @Binding var errorMessage: String?
    var onCreateLaunchAgent: (LaunchAgentDraft) -> Void

    @State private var isExpanded = false
    @State private var showingKillConfirm = false
    @State private var copyConfirmed = false
    @State private var renameText = ""
    @State private var isEditingName = false

    private var isKilling: Bool { store.pendingKillIDs.contains(service.id) }

    private var statusColor: Color {
        service.health == .healthy ? BootayarTheme.emerald : BootayarTheme.crimson
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                BootayarStatusBadge(
                    title: service.health == .healthy ? "Listening" : "Unresponsive",
                    color: statusColor,
                    isPulsing: isKilling
                )
                .help("PID \(service.pid)")

                if service.isHomebrewManaged {
                    HomebrewTag()
                }

                summaryText
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                Spacer()

                if isKilling {
                    ProgressView().controlSize(.small)
                } else {
                    primaryActionButton
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .disabled(isKilling)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if isExpanded {
                Divider()
                    .opacity(0.6)
                VStack(alignment: .leading, spacing: 6) {
                    renameSection
                    if service.isHomebrewManaged, let formula = service.brewFormulaName {
                        detailRow("Source", "Homebrew · \(formula)")
                        if let label = service.brewLaunchdLabel {
                            detailRow("Launchd", label)
                        }
                    }
                    if service.identityKind == .hostMechanism {
                        detailRow("Type", String(localized: "Host Mechanism"))
                    }
                    if let docker = service.dockerInfo {
                        detailRow("Container", docker.containerLabel)
                        detailRow("Image", docker.image)
                        if let project = docker.composeProject {
                            detailRow("Compose", project)
                        }
                        detailRow("Container ID", docker.shortID)
                    }
                    detailRow("Program", FilePathNormalizer.display(service.command))
                    detailRow("PID", "\(service.pid)")
                    detailRow("Executable", FilePathNormalizer.display(service.executable))
                    if let projectDir = service.workingDirectory {
                        detailRow("Project Dir", FilePathNormalizer.display(projectDir))
                    }
                    if let processDir = service.processDirectory,
                       processDir != service.workingDirectory {
                        detailRow("Process Dir", FilePathNormalizer.display(processDir))
                    }

                    HStack(spacing: 8) {
                        if service.runtimeGroup == .instance && service.killAllowed,
                           let draft = LaunchAgentDraft.from(service: service) {
                            Button("Create Launch Agent…") {
                                onCreateLaunchAgent(draft)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        Button(copyConfirmed ? "Copied" : "Copy Address") {
                            copyAddress()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(copyConfirmed)

                        if let url = service.url {
                            Button("Open") {
                                NSWorkspace.shared.open(url)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        Button(killButtonTitle, role: .destructive) {
                            showingKillConfirm = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isKilling || !service.killAllowed)
                        .help(service.killBlockedReason ?? "")
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(BootayarTheme.indigo.opacity(0.04))
            }
        }
        .bootayarCard(statusColor: statusColor, isExpanded: isExpanded)
        .confirmationDialog(
            killDialogTitle,
            isPresented: $showingKillConfirm,
            titleVisibility: .visible
        ) {
            Button(killConfirmActionTitle, role: .destructive) {
                store.kill(service) { errorMessage = $0 }
            }
        } message: {
            Text(killConfirmMessage)
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                renameText = service.displayName
                isEditingName = false
            }
        }
        .onChange(of: renameText) { _, _ in
            isEditingName = true
        }
        .onChange(of: service.displayName) { _, newName in
            if !isEditingName { renameText = newName }
        }
    }

    private var renameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Display Name")
                    .foregroundStyle(.secondary)
                    .frame(width: 58, alignment: .leading)
                TextField("Display Name", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .onSubmit { saveRename() }
                Button("Save") { saveRename() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if store.hasCustomName(for: service) {
                    Button("Reset to Auto") {
                        store.clearCustomName(for: service)
                        renameText = service.autoDisplayName
                        isEditingName = false
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }
            if store.hasCustomName(for: service) {
                Text(String(localized: "Custom name set (auto-detected: \(service.autoDisplayName))"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .padding(.bottom, 4)
    }

    private func saveRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if trimmed == service.autoDisplayName {
            store.clearCustomName(for: service)
        } else {
            store.setCustomName(trimmed, for: service)
        }
        isEditingName = false
    }

    private var summaryText: some View {
        HStack(spacing: 6) {
            Text(service.displayName)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(0)

            if let subtitle = service.subtitle {
                Text("·")
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(-1)
            }

            Spacer(minLength: 8)

            Text(service.addressLabel)
                .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(BootayarTheme.indigo)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(BootayarTheme.indigo.opacity(0.10))
                )
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
        }
    }

    private var killButtonTitle: LocalizedStringKey {
        service.usesDockerStop ? "Stop Container…" : "Terminate Process…"
    }

    private var killDialogTitle: LocalizedStringKey {
        service.usesDockerStop ? "Stop Container?" : "Terminate Service?"
    }

    private var killConfirmActionTitle: LocalizedStringKey {
        service.usesDockerStop ? "Stop Container" : "Terminate Process"
    }

    private var killConfirmMessage: String {
        var lines = [service.displayName, service.addressLabel]
        if let docker = service.dockerInfo {
            lines.append(String(localized: "Container: \(docker.containerLabel)"))
            lines.append(String(localized: "Image: \(docker.image)"))
        } else {
            lines.append(String(localized: "PID \(service.pid)"))
        }
        if let dir = service.workingDirectory {
            lines.append(FilePathNormalizer.display(dir))
        }
        return lines.joined(separator: "\n")
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        if let url = service.url {
            Button("Open") {
                NSWorkspace.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        } else {
            Button(copyConfirmed ? "Copied" : "Copy Address") {
                copyAddress()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(copyConfirmed)
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

    private func copyAddress() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(service.addressLabel, forType: .string)
        copyConfirmed = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            copyConfirmed = false
        }
    }
}
