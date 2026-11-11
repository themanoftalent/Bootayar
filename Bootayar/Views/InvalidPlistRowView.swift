import SwiftUI

struct InvalidPlistRowView: View {
    let item: InvalidPlist
    @ObservedObject var store: AgentStore
    @Binding var errorMessage: String?

    @State private var isExpanded = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                BootayarStatusBadge(
                    title: "Invalid",
                    color: BootayarTheme.crimson
                )

                Text(item.url.lastPathComponent)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if isExpanded {
                Divider()
                    .opacity(0.6)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(L("Path"))
                            .foregroundStyle(.secondary)
                            .frame(width: 42, alignment: .leading)
                        Text(FilePathNormalizer.display(item.url.path))
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .font(.caption)
                    Text(L("This file is empty or malformed and cannot be loaded by launchd."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(BootayarTheme.crimson.opacity(0.04))
            }
        }
        .bootayarCard(statusColor: BootayarTheme.crimson, isExpanded: isExpanded)
        .confirmationDialog(
            L("Delete \(item.url.lastPathComponent)?"),
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L("Delete"), role: .destructive) {
                do { try store.deleteInvalid(item) }
                catch { errorMessage = error.localizedDescription }
            }
        } message: {
            Text(L("This will permanently delete the plist file. This cannot be undone."))
        }
    }
}
