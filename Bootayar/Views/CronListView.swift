import SwiftUI

struct CronListView: View {
    @ObservedObject var store: CrontabStore
    var searchText: String
    @Binding var newCronScope: CrontabScope
    @Binding var showingNewCron: Bool
    @Binding var errorMessage: String?

    @State private var collapsedGroups: Set<CrontabScope> = []

    private var filteredJobsByScope: [CrontabScope: [CronJob]] {
        Dictionary(uniqueKeysWithValues: CrontabScope.allCases.map { scope in
            let jobs = store.jobs(for: scope)
            guard !searchText.isEmpty else { return (scope, jobs) }
            let filtered = jobs.filter {
                $0.command.localizedCaseInsensitiveContains(searchText) ||
                $0.scheduleDescription.localizedCaseInsensitiveContains(searchText) ||
                ($0.runAsUser?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            return (scope, filtered)
        })
    }

    private var groupedScopes: [CrontabScope] {
        CrontabScope.allCases.filter { scope in
            !(filteredJobsByScope[scope] ?? []).isEmpty || !store.preambleLines(for: scope).isEmpty
        }
    }

    private var hasVisibleContent: Bool {
        !groupedScopes.isEmpty
    }

    var body: some View {
        Group {
            if !hasVisibleContent {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "clock",
                    description: Text(emptyDescription)
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(groupedScopes, id: \.self) { scope in
                            cronGroupSection(scope: scope)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(L("Crontab"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(CrontabScope.allCases, id: \.self) { scope in
                        Button {
                            newCronScope = scope
                            showingNewCron = true
                        } label: {
                            Label(scope.newJobMenuTitle, systemImage: scope.systemImage)
                        }
                    }
                } label: {
                    Label(L("New"), systemImage: "plus")
                }
            }
            ToolbarItem {
                Button { store.refresh() } label: {
                    Label(L("Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(store.isRefreshing)
            }
        }
    }

    private func cronGroupSection(scope: CrontabScope) -> some View {
        let jobs = filteredJobsByScope[scope] ?? []
        let preamble = store.preambleLines(for: scope)
        let count = jobs.count
        let isCollapsed = collapsedGroups.contains(scope)

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if isCollapsed {
                        collapsedGroups.remove(scope)
                    } else {
                        collapsedGroups.insert(scope)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(BootayarTheme.indigo.opacity(0.14))
                            .frame(width: 26, height: 26)
                        Image(systemName: scope.systemImage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BootayarTheme.indigo)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(scope.sectionTitle)
                            .font(.system(size: 13.5, weight: .semibold))
                        Text(scope.sectionSubtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(L("\(count)"))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(BootayarTheme.indigo)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(BootayarTheme.indigo.opacity(0.12)))
                    Spacer()
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                if !preamble.isEmpty {
                    preambleSection(scope: scope, lines: preamble)
                }
                ForEach(jobs) { job in
                    CronRowView(job: job, store: store, errorMessage: $errorMessage)
                }
            }
        }
    }

    private func preambleSection(scope: CrontabScope, lines: [CrontabLine]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scope == .system ? "File Header" : "Crontab Header")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BootayarTheme.indigo)
            ForEach(lines) { line in
                Text(preambleText(for: line))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(BootayarTheme.indigo.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(BootayarTheme.indigo.opacity(0.18), lineWidth: 1)
        )
    }

    private func preambleText(for line: CrontabLine) -> String {
        switch line {
        case .blank:
            return ""
        case .comment(_, let text):
            return text
        case .environment(_, let key, let value):
            return "\(key)=\(value)"
        case .job:
            return ""
        case .raw(_, let text):
            return text
        }
    }

    private var emptyTitle: String {
        searchText.isEmpty ? "No Cron Jobs" : "No Matching Results"
    }

    private var emptyDescription: String {
        searchText.isEmpty
            ? "User crontab and /etc/crontab are empty. Click New to add a scheduled job."
            : "Try a different search query"
    }
}
