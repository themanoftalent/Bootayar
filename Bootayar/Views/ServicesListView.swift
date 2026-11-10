import SwiftUI

struct ServicesListView: View {
    @ObservedObject var store: ServiceStore
    @Binding var errorMessage: String?
    var onCreateLaunchAgent: (LaunchAgentDraft) -> Void

    @State private var searchText = ""
    @State private var collapsedGroups: Set<ServiceRuntimeGroup> = []

    private var filteredServices: [Service] {
        guard !searchText.isEmpty else { return store.services }
        return store.services.filter { service in
            service.displayName.localizedCaseInsensitiveContains(searchText) ||
            (service.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            String(service.port).contains(searchText) ||
            service.executable.localizedCaseInsensitiveContains(searchText) ||
            service.addressLabel.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedServices: [(ServiceRuntimeGroup, [Service])] {
        ServiceRuntimeGroup.allCases.compactMap { group in
            let items = filteredServices.filter { $0.runtimeGroup == group }
            return items.isEmpty ? nil : (group, items)
        }
    }

    var body: some View {
        Group {
            if filteredServices.isEmpty {
                ContentUnavailableView(
                    emptyStateTitle,
                    systemImage: store.lastScanError == nil ? "bolt.slash" : "exclamationmark.triangle",
                    description: Text(emptyStateDescription)
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(groupedServices, id: \.0) { group, services in
                            serviceGroupSection(group: group, services: services)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Services")
        .searchable(text: $searchText, prompt: "Search service, port, or project…")
        .toolbar {
            if store.lastScanError != nil {
                ToolbarItem {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(BootayarTheme.amber)
                        .help(store.lastScanError ?? "")
                }
            }
            ToolbarItem {
                Toggle("Show All", isOn: $store.showAll)
            }
            ToolbarItem {
                Button { store.refreshNow() } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private var emptyStateTitle: LocalizedStringKey {
        if store.lastScanError != nil { return "Scan Failed" }
        if !store.showAll { return "No Dev Services Found" }
        return "No Services Found"
    }

    private var emptyStateDescription: String {
        if let error = store.lastScanError { return error }
        if !store.showAll {
            return String(localized: "Start a dev server or enable Show All")
        }
        return String(localized: "No listening TCP services found")
    }

    private func serviceGroupSection(group: ServiceRuntimeGroup, services: [Service]) -> some View {
        let isCollapsed = collapsedGroups.contains(group)

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if isCollapsed {
                        collapsedGroups.remove(group)
                    } else {
                        collapsedGroups.insert(group)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(BootayarTheme.electricViolet.opacity(0.14))
                            .frame(width: 26, height: 26)
                        Image(systemName: group.systemImage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BootayarTheme.electricViolet)
                    }
                    Text(group.title)
                        .font(.system(size: 13.5, weight: .semibold))
                    Text("\(services.count)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(BootayarTheme.electricViolet)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(BootayarTheme.electricViolet.opacity(0.12)))
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
            .accessibilityLabel(isCollapsed ? "Expand \(group.title)" : "Collapse \(group.title)")

            if !isCollapsed {
                ForEach(services) { service in
                    ServiceRowView(
                        service: service,
                        store: store,
                        errorMessage: $errorMessage,
                        onCreateLaunchAgent: onCreateLaunchAgent
                    )
                }
            }
        }
    }
}
