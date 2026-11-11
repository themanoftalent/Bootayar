import SwiftUI

struct CronRowView: View {
    let job: CronJob
    @ObservedObject var store: CrontabStore
    @Binding var errorMessage: String?

    @State private var isExpanded = false
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    private var statusColor: Color {
        job.isEnabled ? BootayarTheme.emerald : BootayarTheme.amber
    }

    private var statusTooltip: String {
        job.isEnabled ? "Enabled" : "Disabled"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                BootayarStatusBadge(
                    title: statusTooltip,
                    color: statusColor
                )
                .help(statusTooltip)

                if job.scope == .system, let user = job.runAsUser {
                    Text(user)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(BootayarTheme.indigo)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(BootayarTheme.indigo.opacity(0.12)))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.command)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(job.scheduleDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                primaryActionButton

                HStack(spacing: 4) {
                    Button { showingEdit = true } label: {
                        Image(systemName: "pencil")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) { isExpanded.toggle() }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if isExpanded {
                Divider()
                    .opacity(0.6)
                VStack(alignment: .leading, spacing: 6) {
                    detailRow("Schedule", job.scheduleDescription)
                    detailRow("Expression", expressionText)
                    if let user = job.runAsUser {
                        detailRow("User", user)
                    }
                    detailRow("Command", FilePathNormalizer.display(job.command))
                    detailRow("Source", job.scope.sourceDescription)
                    if job.scope.requiresPrivilege {
                        detailRow("Privilege", L("Administrator password required to save"))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(BootayarTheme.indigo.opacity(0.04))
            }
        }
        .bootayarCard(statusColor: statusColor, isExpanded: isExpanded)
        .sheet(isPresented: $showingEdit) {
            EditCronSheet(existingJob: job, scope: job.scope, store: store, errorMessage: $errorMessage)
        }
        .confirmationDialog(
            L("Delete this Cron job?"),
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L("Delete"), role: .destructive) {
                do { try store.deleteJob(id: job.id, scope: job.scope) }
                catch PrivilegeError.cancelled { }
                catch { errorMessage = error.localizedDescription }
            }
        } message: {
            Text(job.command)
        }
    }

    private var expressionText: String {
        if let user = job.runAsUser {
            return (job.scheduleFields + [user]).joined(separator: " ")
        }
        return job.scheduleFields.joined(separator: " ")
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        if job.isEnabled {
            Button(L("Disable")) {
                do { try store.setEnabled(id: job.id, scope: job.scope, enabled: false) }
                catch PrivilegeError.cancelled { }
                catch { errorMessage = error.localizedDescription }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        } else {
            Button(L("Enable")) {
                do { try store.setEnabled(id: job.id, scope: job.scope, enabled: true) }
                catch PrivilegeError.cancelled { }
                catch { errorMessage = error.localizedDescription }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
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
