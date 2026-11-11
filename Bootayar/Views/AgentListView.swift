import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct AgentListView: View {
    @ObservedObject var store: AgentStore
    @ObservedObject var homebrewStore: HomebrewServiceStore
    var searchText: String
    @Binding var newAgentScope: LaunchItem.Scope
    @Binding var showingNewAgent: Bool
    @Binding var showingNewFromXml: Bool
    @Binding var errorMessage: String?

    @State private var listFilter: AgentListFilter = .all
    @State private var collapsedGroups: Set<LaunchItem.Scope> = []
    @State private var importRequest: ImportPlistRequest?
    @State private var bootstrapAfterImport: LaunchItem?

    private struct ImportPlistRequest: Identifiable {
        let id = UUID()
        let url: URL
    }

    private var brewLookup: [String: HomebrewService] {
        homebrewStore.servicesByLabel
    }

    private var registeredLabels: Set<String> {
        Set(store.items.map(\.label))
    }

    private var brewActions: BrewRowActions {
        BrewRowActions(
            onStart: { homebrewStore.start($0) { errorMessage = $0 } },
            onStop: { homebrewStore.stop($0) { errorMessage = $0 } },
            onRestart: { homebrewStore.restart($0) { errorMessage = $0 } }
        )
    }

    private var unregisteredBrewServices: [HomebrewService] {
        let orphans = homebrewStore.unregisteredServices(excludingLabels: registeredLabels)
        guard !searchText.isEmpty else { return orphans }
        return orphans.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.label.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredItems: [LaunchItem] {
        var items = store.items
        items = applyScopeFilter(to: items)
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.label.localizedCaseInsensitiveContains(searchText) ||
            $0.program.localizedCaseInsensitiveContains(searchText) ||
            ($0.brewFormulaName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var filteredInvalidItems: [InvalidPlist] {
        var invalid = store.invalidItems
        if case .scope(let scope) = listFilter {
            invalid = invalid.filter { $0.scope == scope }
        } else if listFilter == .homebrew {
            invalid = []
        }
        guard !searchText.isEmpty else { return invalid }
        return invalid.filter {
            $0.url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedScopes: [LaunchItem.Scope] {
        LaunchItem.Scope.allCases.filter { scope in
            filteredItems.contains { $0.scope == scope } ||
            filteredInvalidItems.contains { $0.scope == scope }
        }
    }

    private var hasVisibleContent: Bool {
        !filteredItems.isEmpty || !filteredInvalidItems.isEmpty || !unregisteredBrewServices.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(BootayarTheme.subtleHeaderGradient)
            Divider()
                .opacity(0.6)

            Group {
                if !hasVisibleContent {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: listFilter == .homebrew ? "mug" : "tray",
                        description: Text(emptyDescription)
                    )
                } else if listFilter == .homebrew {
                    homebrewListContent
                } else {
                    groupedListContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(L("Launch Agents"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(LaunchItem.Scope.allCases, id: \.self) { scope in
                        Button {
                            newAgentScope = scope
                            showingNewAgent = true
                        } label: {
                            Label(scope.newAgentMenuTitle, systemImage: scope.systemImage)
                        }
                    }
                    Divider()
                    Button {
                        newAgentScope = .userAgent
                        showingNewFromXml = true
                    } label: {
                        Label(L("Paste from XML…"), systemImage: "doc.on.clipboard")
                    }
                } label: {
                    Label(L("New"), systemImage: "plus")
                }
            }
            ToolbarItem {
                Button { pickAndImportPlist() } label: {
                    Label(L("Import"), systemImage: "square.and.arrow.down")
                }
            }
            ToolbarItem {
                Button { refreshAll() } label: {
                    Label(L("Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(homebrewStore.isRefreshing)
            }
        }
        .sheet(item: $importRequest) { request in
            ImportPlistSheet(
                sourceURL: request.url,
                store: store,
                errorMessage: $errorMessage,
                onImported: { item in bootstrapAfterImport = item }
            )
        }
        .confirmationDialog(L("Load Agent Now?"),
            isPresented: Binding(
                get: { bootstrapAfterImport != nil },
                set: { if !$0 { bootstrapAfterImport = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L("Load")) {
                if let item = bootstrapAfterImport {
                    store.bootstrap(item) { errorMessage = $0 }
                }
                bootstrapAfterImport = nil
            }
            Button(L("Later"), role: .cancel) {
                bootstrapAfterImport = nil
            }
        } message: {
            if let item = bootstrapAfterImport {
                Text(item.label)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(.all, icon: "square.grid.2x2.fill")
                filterChip(.homebrew, icon: "mug.fill")
                ForEach(LaunchItem.Scope.allCases, id: \.self) { scope in
                    filterChip(.scope(scope), icon: scope.systemImage)
                }
            }
        }
    }

    private var homebrewListContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                if !unregisteredBrewServices.isEmpty {
                    unregisteredSection
                        .padding(.bottom, 8)
                }
                ForEach(filteredItems) { item in
                    agentRow(for: item)
                }
            }
            .padding(16)
        }
    }

    private var groupedListContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(groupedScopes, id: \.self) { scope in
                    agentGroupSection(scope: scope)
                }
            }
            .padding(16)
        }
    }

    private func filterChip(_ filter: AgentListFilter, icon: String? = nil) -> some View {
        let isSelected = listFilter == filter
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                listFilter = filter
            }
        } label: {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10.5, weight: .semibold))
                }
                Text(filter.chipTitle)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? chipTextColor(for: filter) : .primary)
            .padding(.horizontal, 11)
            .padding(.vertical, 5.5)
            .background(
                Capsule()
                    .fill(isSelected ? chipFillColor(for: filter) : AnyShapeStyle(Color(nsColor: .controlBackgroundColor)))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? chipStrokeColor(for: filter) : Color(nsColor: .separatorColor).opacity(0.65),
                        lineWidth: isSelected ? 1.2 : 1.0
                    )
            )
            .shadow(color: isSelected ? BootayarTheme.indigo.opacity(0.16) : .clear, radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func chipFillColor(for filter: AgentListFilter) -> AnyShapeStyle {
        if filter == .homebrew {
            return AnyShapeStyle(BootayarTheme.amber.opacity(0.18))
        }
        return AnyShapeStyle(BootayarTheme.brandGradient)
    }

    private func chipStrokeColor(for filter: AgentListFilter) -> Color {
        filter == .homebrew ? BootayarTheme.amber : BootayarTheme.electricViolet
    }

    private func chipTextColor(for filter: AgentListFilter) -> Color {
        filter == .homebrew ? BootayarTheme.amber : .white
    }

    private var unregisteredSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(BootayarTheme.amber.opacity(0.15))
                        .frame(width: 24, height: 24)
                    Image(systemName: "mug.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BootayarTheme.amber)
                }
                Text(L("Unregistered Homebrew Services"))
                    .font(.headline)
                Text(L("\(unregisteredBrewServices.count)"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(BootayarTheme.amber)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(BootayarTheme.amber.opacity(0.14)))
            }
            .padding(.horizontal, 4)

            ForEach(unregisteredBrewServices) { service in
                HomebrewServiceRowView(
                    service: service,
                    store: homebrewStore,
                    errorMessage: $errorMessage,
                    startButtonTitle: "Register & Start"
                )
            }
        }
    }

    private func agentRow(for item: LaunchItem) -> some View {
        let brew = brewLookup[item.label]
        return AgentRowView(
            item: item,
            brewService: brew,
            brewPending: brew.flatMap { homebrewStore.pendingOperations[$0.id] },
            brewActions: brew == nil ? nil : brewActions,
            store: store,
            errorMessage: $errorMessage
        )
    }

    private func refreshAll() {
        store.refresh()
        homebrewStore.refresh()
    }

    private func applyScopeFilter(to items: [LaunchItem]) -> [LaunchItem] {
        switch listFilter {
        case .all:
            return items
        case .homebrew:
            return items.filter(\.isBrewManaged)
        case .scope(let scope):
            return items.filter { $0.scope == scope }
        }
    }

    private func pickAndImportPlist() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.propertyList]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        importRequest = ImportPlistRequest(url: url)
    }

    private var emptyTitle: String {
        if listFilter == .homebrew {
            return searchText.isEmpty ? "No Homebrew Services" : "No Matching Results"
        }
        return searchText.isEmpty ? "No Agents" : "No Matching Results"
    }

    private var emptyDescription: String {
        if listFilter == .homebrew {
            return searchText.isEmpty
                ? "Installed brew formulas will appear in their scope once started"
                : "Try a different search query"
        }
        return searchText.isEmpty
            ? "No LaunchAgents or LaunchDaemons found"
            : "Try a different search query"
    }

    private func items(for scope: LaunchItem.Scope) -> [LaunchItem] {
        filteredItems.filter { $0.scope == scope }
    }

    private func invalidItems(for scope: LaunchItem.Scope) -> [InvalidPlist] {
        filteredInvalidItems.filter { $0.scope == scope }
    }

    private func agentGroupSection(scope: LaunchItem.Scope) -> some View {
        let items = items(for: scope)
        let invalid = invalidItems(for: scope)
        let count = items.count + invalid.count
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
            .accessibilityLabel(isCollapsed ? "Expand \(scope.sectionTitle)" : "Collapse \(scope.sectionTitle)")

            if !isCollapsed {
                ForEach(items) { item in
                    agentRow(for: item)
                }
                ForEach(invalid) { item in
                    InvalidPlistRowView(item: item, store: store, errorMessage: $errorMessage)
                }
            }
        }
    }
}
