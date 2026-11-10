import AppKit
import SwiftUI

struct EditAgentSheet: View {
    let existingItem: LaunchItem?
    let defaultScope: LaunchItem.Scope
    @ObservedObject var store: AgentStore
    @Environment(\.dismiss) private var dismiss

    @State private var editorMode: EditorMode
    @State private var label: String
    @State private var program: String
    @State private var argumentsText: String
    @State private var workingDirectory: String
    @State private var session: TriggerDocumentSession?
    @State private var rules: [TriggerRule]
    @State private var pathIdsInOrder: [UUID]
    @State private var runAtLoad: Bool
    @State private var keepAlive: Bool
    @State private var stdoutPath: String
    @State private var stderrPath: String
    @State private var envVarRows: [EnvVarRow]
    @State private var xmlText: String
    @State private var xmlError: String?
    @State private var formDisabledReason: String?
    @State private var errorMessage: String?
    @State private var pendingDeleteRuleID: UUID?
    @State private var showDiskChangedAlert = false
    @State private var showRunAtLoadSaveConfirm = false

    private let plistService = PlistService()

    init(
        existingItem: LaunchItem?,
        defaultScope: LaunchItem.Scope,
        store: AgentStore,
        draft: LaunchAgentDraft? = nil,
        initialXml: String? = nil
    ) {
        self.existingItem = existingItem
        self.defaultScope = defaultScope
        self.store = store

        let i = existingItem
        let d = draft

        _editorMode = State(initialValue: initialXml != nil ? .xml : .form)
        _label = State(initialValue: d?.label ?? i?.label ?? "")
        _program = State(initialValue: d?.program ?? i?.program ?? "")
        _argumentsText = State(initialValue: d?.programArguments.joined(separator: "\n") ?? i?.programArguments.joined(separator: "\n") ?? "")
        _workingDirectory = State(initialValue: d?.workingDirectory ?? i?.workingDirectory ?? "")

        if let item = existingItem, let opened = try? TriggerDocumentSession(url: item.plistURL) {
            _session = State(initialValue: opened)
            _rules = State(initialValue: opened.rules)
            _pathIdsInOrder = State(initialValue: opened.pathIdsInOrder)
        } else {
            _session = State(initialValue: nil)
            _rules = State(initialValue: [])
            _pathIdsInOrder = State(initialValue: [])
        }

        _runAtLoad = State(initialValue: d?.runAtLoad ?? i?.runAtLoad ?? false)
        _keepAlive = State(initialValue: d?.keepAlive ?? i?.keepAlive ?? false)
        _stdoutPath = State(initialValue: i?.standardOutPath ?? "")
        _stderrPath = State(initialValue: i?.standardErrorPath ?? "")
        _envVarRows = State(initialValue: Self.envRows(from: i?.environmentVariables ?? [:]))
        _xmlText = State(initialValue: initialXml ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Edit Mode", selection: $editorMode) {
                Text("Form").tag(EditorMode.form)
                Text("XML").tag(EditorMode.xml)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            .onChange(of: editorMode) { _, mode in
                switch mode {
                case .xml:
                    loadXmlFromCurrentState()
                case .form:
                    syncFormFromXmlIfPossible()
                }
            }

            if editorMode == .form {
                if let reason = formDisabledReason {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                formContent
            } else {
                xmlContent
            }

            if existingItem == nil {
                templatesFooter
            }
        }
        .frame(minWidth: 480, minHeight: 360)
        .navigationTitle(existingItem == nil ? "New Agent" : "Edit Agent")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { requestSave() }
                    .disabled(!canSave)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            String(localized: "Saving will reload the job and may run it immediately."),
            isPresented: $showRunAtLoadSaveConfirm,
            titleVisibility: .visible
        ) {
            Button("Save", role: .destructive) { saveItem() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Saving will reload the job and may run it immediately.")
        }
        .alert("File Modified on Disk", isPresented: $showDiskChangedAlert) {
            Button("Reload") { reloadSessionFromDisk() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The file on disk was modified externally. Reloading will discard unsaved changes.")
        }
        .confirmationDialog(
            "Delete Group",
            isPresented: Binding(
                get: { pendingDeleteRuleID != nil },
                set: { if !$0 { pendingDeleteRuleID = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Group", role: .destructive) {
                if let id = pendingDeleteRuleID {
                    removeRule(id: id)
                }
                pendingDeleteRuleID = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteRuleID = nil
            }
        } message: {
            Text("This rule maps to multiple calendar entries. Deleting it will remove the entire group.")
        }
        .onAppear {
            if editorMode == .xml && xmlText.isEmpty {
                loadXmlFromCurrentState()
            }
            validateXmlText()
            checkFormCompatibilityFromDisk()
        }
        .onChange(of: xmlText) { _, _ in
            validateXmlText()
        }
    }

    // MARK: - Form

    private var formContent: some View {
        Form {
            Section("Basic Info") {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 0) {
                            Text("Label").font(.caption).foregroundStyle(.secondary)
                            Text(" *").font(.caption).foregroundStyle(.red)
                        }
                        TextField("e.g. com.example.mytask", text: $label)
                            .textFieldStyle(.roundedBorder)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 0) {
                            Text("Program Path").font(.caption).foregroundStyle(.secondary)
                            Text(" *").font(.caption).foregroundStyle(.red)
                        }
                        HStack {
                            TextField("e.g. /usr/local/bin/mytool", text: $program)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse…") { pickProgram() }
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        TextEditor(text: $argumentsText)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 64)
                            .background(Color(.textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.separatorColor), lineWidth: 1)
                            )
                        Text("One argument per line").font(.caption).foregroundStyle(.secondary)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Working Directory").font(.caption).foregroundStyle(.secondary)
                        TextField("WorkingDirectory (optional)", text: $workingDirectory)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            Section("Triggers") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trigger rules act independently; the job starts when any rule fires.")
                    Text("Order is for display only and does not affect priority.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                ForEach(rules) { rule in
                    ruleEditor(for: rule)
                }

                // Use Menu so macOS does not truncate options
                Menu {
                    Button("Daily") { addRule(.daily(hour: 8, minute: 0)) }
                    Button("Weekly") { addRule(.weekly(weekdays: [1], hour: 8, minute: 0)) }
                    Button("Monthly") { addRule(.monthly(day: 1, hour: 8, minute: 0, months: nil)) }
                    Button("Yearly") { addRule(.yearly(month: 1, day: 1, hour: 8, minute: 0)) }
                    Button("Interval") { addRule(.interval(seconds: 60)) }
                        .disabled(hasIntervalRule)
                    Button("Watch Path") { addWatchPathRule() }
                } label: {
                    Label("Add Rule", systemImage: "plus")
                }
            }

            if !passthroughLaunchEntries.isEmpty {
                Section("Other Trigger Conditions") {
                    ForEach(passthroughLaunchEntries, id: \.key) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.key)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.summary)
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            Section("Options") {
                Toggle("Run at Login", isOn: $runAtLoad)
                Text("Run once when loaded at login; also runs when manually reloaded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if runAtLoadSaveWarningVisible {
                    Text("Saving will reload the job and may run it immediately.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Toggle("Keep Alive (restart automatically on crash)", isOn: $keepAlive)
            }

            Section("Environment Variables (optional)") {
                if envVarRows.isEmpty {
                    Text("No environment variables").font(.caption).foregroundStyle(.secondary)
                }
                ForEach($envVarRows) { $row in
                    HStack(spacing: 8) {
                        TextField("KEY", text: $row.key)
                            .textFieldStyle(.roundedBorder)
                        TextField("value", text: $row.value)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            envVarRows.removeAll { $0.id == row.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                Button {
                    envVarRows.append(EnvVarRow())
                } label: {
                    Label("Add Variable", systemImage: "plus")
                }
            }

            Section("Log Paths (optional)") {
                TextField("StandardOutPath", text: $stdoutPath)
                TextField("StandardErrorPath", text: $stderrPath)
            }
        }
        .formStyle(.grouped)
        .disabled(formDisabledReason != nil)
    }

    @ViewBuilder
    private func ruleEditor(for rule: TriggerRule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ruleKindTitle(rule.kind))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    requestDelete(rule)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }

            switch rule.kind {
            case .daily(let hour, let minute):
                timeFields(
                    hour: hour,
                    minute: minute,
                    onHour: { newHour in
                        updateKind(rule.id, .daily(hour: newHour, minute: minute))
                    },
                    onMinute: { newMinute in
                        updateKind(rule.id, .daily(hour: hour, minute: newMinute))
                    }
                )

            case .weekly(let weekdays, let hour, let minute):
                weekdayToggles(selected: Set(weekdays.map { $0 == 0 ? 7 : $0 })) { newDays in
                    updateKind(rule.id, .weekly(weekdays: newDays.sorted(), hour: hour, minute: minute))
                }
                timeFields(
                    hour: hour,
                    minute: minute,
                    onHour: { newHour in
                        updateKind(rule.id, .weekly(weekdays: weekdays, hour: newHour, minute: minute))
                    },
                    onMinute: { newMinute in
                        updateKind(rule.id, .weekly(weekdays: weekdays, hour: hour, minute: newMinute))
                    }
                )

            case .monthly(let day, let hour, let minute, let months):
                HStack(spacing: 12) {
                    labeledIntField("Day", value: day, width: 52) { newDay in
                        updateKind(
                            rule.id,
                            .monthly(day: min(max(newDay, 1), 31), hour: hour, minute: minute, months: months)
                        )
                    }
                    timeFields(
                        hour: hour,
                        minute: minute,
                        onHour: { newHour in
                            updateKind(rule.id, .monthly(day: day, hour: newHour, minute: minute, months: months))
                        },
                        onMinute: { newMinute in
                            updateKind(rule.id, .monthly(day: day, hour: hour, minute: newMinute, months: months))
                        }
                    )
                }
                monthModePicker(months: months) { newMonths in
                    updateKind(rule.id, .monthly(day: day, hour: hour, minute: minute, months: newMonths))
                }

            case .yearly(let month, let day, let hour, let minute):
                HStack(spacing: 12) {
                    labeledIntField("Month", value: month, width: 52) { newMonth in
                        updateKind(
                            rule.id,
                            .yearly(month: min(max(newMonth, 1), 12), day: day, hour: hour, minute: minute)
                        )
                    }
                    labeledIntField("Day", value: day, width: 52) { newDay in
                        updateKind(
                            rule.id,
                            .yearly(month: month, day: min(max(newDay, 1), 31), hour: hour, minute: minute)
                        )
                    }
                    timeFields(
                        hour: hour,
                        minute: minute,
                        onHour: { newHour in
                            updateKind(rule.id, .yearly(month: month, day: day, hour: newHour, minute: minute))
                        },
                        onMinute: { newMinute in
                            updateKind(rule.id, .yearly(month: month, day: day, hour: hour, minute: newMinute))
                        }
                    )
                }

            case .interval(let seconds):
                intervalEditor(ruleID: rule.id, seconds: seconds)

            case .watchPath(let path):
                TextField("Watch Path", text: Binding(
                    get: { path },
                    set: { newPath in
                        updateKind(rule.id, .watchPath(newPath))
                    }
                ))
                .textFieldStyle(.roundedBorder)
                Text("Watches the specified path for changes. Events may coalesce.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .customCalendar(let summary, let isMalformed):
                if isMalformed {
                    Text("Invalid Config")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                } else {
                    Text("Custom Calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(summary.isEmpty ? "—" : summary)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Text("Please use XML mode to edit this rule.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Edit in XML") {
                    loadXmlFromCurrentState()
                    editorMode = .xml
                }
                .buttonStyle(.link)
            }
        }
        .padding(.vertical, 4)
    }

    private func timeFields(
        hour: Int,
        minute: Int,
        onHour: @escaping (Int) -> Void,
        onMinute: @escaping (Int) -> Void
    ) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            labeledIntField("Hour", value: hour, width: 52) { onHour(min(max($0, 0), 23)) }
            Text(":").foregroundStyle(.secondary).padding(.bottom, 6)
            labeledIntField("Min", value: minute, width: 52) { onMinute(min(max($0, 0), 59)) }
        }
    }

    private func labeledIntField(
        _ title: LocalizedStringKey,
        value: Int,
        width: CGFloat,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(
                "",
                value: Binding(
                    get: { value },
                    set: onChange
                ),
                format: .number
            )
            .textFieldStyle(.roundedBorder)
            .frame(width: width)
            .multilineTextAlignment(.center)
        }
    }

    // launchd weekday: 0/7 = Sun, 1 = Mon ... 6 = Sat
    private func weekdayToggles(selected: Set<Int>, onChange: @escaping (Set<Int>) -> Void) -> some View {
        let labels = [
            (1, String(localized: "Mon")),
            (2, String(localized: "Tue")),
            (3, String(localized: "Wed")),
            (4, String(localized: "Thu")),
            (5, String(localized: "Fri")),
            (6, String(localized: "Sat")),
            (7, String(localized: "Sun")),
        ]
        return VStack(alignment: .leading, spacing: 6) {
            Text("Weekdays").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(labels, id: \.0) { value, title in
                    Toggle(title, isOn: Binding(
                        get: { selected.contains(value) },
                        set: { isOn in
                            var next = selected
                            if isOn { next.insert(value) } else { next.remove(value) }
                            if next.isEmpty { next = [value] }
                            onChange(next)
                        }
                    ))
                    .toggleStyle(.button)
                }
            }
        }
    }

    private func monthModePicker(
        months: Set<Int>?,
        onChange: @escaping (Set<Int>?) -> Void
    ) -> some View {
        let mode = MonthSelectionMode(months: months)
        return VStack(alignment: .leading, spacing: 8) {
            Picker("Months", selection: Binding(
                get: { mode },
                set: { newMode in
                    switch newMode {
                    case .all:
                        onChange(nil)
                    case .quarter:
                        onChange([1, 4, 7, 10])
                    case .halfYear:
                        onChange([1, 7])
                    case .custom:
                        if let months, !months.isEmpty, MonthSelectionMode(months: months) == .custom {
                            onChange(months)
                        } else {
                            onChange([Calendar.current.component(.month, from: Date())])
                        }
                    }
                }
            )) {
                Text("Every Month").tag(MonthSelectionMode.all)
                Text("Quarterly").tag(MonthSelectionMode.quarter)
                Text("Semi-Annually").tag(MonthSelectionMode.halfYear)
                Text("Custom Months").tag(MonthSelectionMode.custom)
            }
            .pickerStyle(.menu)

            if mode == .custom {
                let selected = months ?? []
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 6) {
                    ForEach(1...12, id: \.self) { month in
                        Toggle("\(month)", isOn: Binding(
                            get: { selected.contains(month) },
                            set: { isOn in
                                var next = selected
                                if isOn { next.insert(month) } else { next.remove(month) }
                                onChange(next.isEmpty ? [month] : next)
                            }
                        ))
                        .toggleStyle(.button)
                    }
                }
            }

            if let months, mode != .all {
                Text(monthCaption(months: months))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func monthCaption(months: Set<Int>) -> String {
        let list = months.sorted().map(String.init).joined(separator: ",")
        return String(format: String(localized: "Months: %@"), locale: .current, list)
    }

    private func intervalEditor(ruleID: UUID, seconds: Int) -> some View {
        let split = IntervalUnit.split(seconds: seconds)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Every")
                    .fixedSize(horizontal: true, vertical: false)
                TextField(
                    "Value",
                    value: Binding(
                        get: { split.amount },
                        set: { amount in
                            let unit = split.unit
                            updateKind(
                                ruleID,
                                .interval(seconds: max(1, amount) * unit.secondsMultiplier)
                            )
                        }
                    ),
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 72)
                .multilineTextAlignment(.trailing)
                Picker("", selection: Binding(
                    get: { split.unit },
                    set: { unit in
                        updateKind(
                            ruleID,
                            .interval(seconds: max(1, split.amount) * unit.secondsMultiplier)
                        )
                    }
                )) {
                    ForEach(IntervalUnit.allCases) { unit in
                        Text(unit.localizedName).tag(unit)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize(horizontal: true, vertical: false)
            }
            if split.unit == .days {
                Text("Every 24 hours (86400s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Triggers may be skipped while asleep or already running.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var xmlContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $xmlText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 280)
                .padding(4)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
                .padding(.horizontal)

            if let xmlError {
                Text(xmlError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private var canSave: Bool {
        switch editorMode {
        case .form:
            return formDisabledReason == nil && !label.isEmpty && !program.isEmpty
        case .xml:
            return xmlError == nil && !xmlText.isEmpty
        }
    }

    private var hasIntervalRule: Bool {
        rules.contains {
            if case .interval = $0.kind { return true }
            return false
        }
    }

    private var passthroughLaunchEntries: [(key: String, summary: String)] {
        let root = session?.root ?? [:]
        return LaunchItem.passthroughLaunchKeys.sorted().compactMap { key in
            guard let value = root[key] else { return nil }
            return (key, Self.describePlistValue(value))
        }
    }

    private var templatesFooter: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                if let url = URL(string: "https://github.com/themanoftalent/Bootayar") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Browse Launch Agent Templates…", systemImage: "safari")
            }
            .buttonStyle(.link)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Rule mutations

    private func ruleKindTitle(_ kind: TriggerRuleKind) -> String {
        switch kind {
        case .daily: return String(localized: "Daily")
        case .weekly: return String(localized: "Weekly")
        case .monthly: return String(localized: "Monthly")
        case .yearly: return String(localized: "Yearly")
        case .interval: return String(localized: "Interval")
        case .watchPath: return String(localized: "Watch Path")
        case .customCalendar(_, let isMalformed):
            return isMalformed
                ? String(localized: "Invalid Config")
                : String(localized: "Custom Calendar")
        }
    }

    private func updateKind(_ id: UUID, _ kind: TriggerRuleKind) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[index].kind = kind
        rules[index].isModified = true
    }

    private func addRule(_ kind: TriggerRuleKind) {
        if case .interval = kind, hasIntervalRule { return }
        rules.append(TriggerRule(
            id: UUID(),
            kind: kind,
            sourceRefs: [],
            isModified: true
        ))
    }

    private func addWatchPathRule() {
        let pathID = UUID()
        rules.append(TriggerRule(
            id: UUID(),
            kind: .watchPath(""),
            sourceRefs: [.watchPath(pathID)],
            isModified: true
        ))
        pathIdsInOrder.append(pathID)
    }

    private func requestDelete(_ rule: TriggerRule) {
        let multiRef: Bool = {
            switch rule.kind {
            case .weekly, .monthly:
                return rule.sourceRefs.count > 1
            default:
                return false
            }
        }()
        if multiRef {
            pendingDeleteRuleID = rule.id
        } else {
            removeRule(id: rule.id)
        }
    }

    private func removeRule(id: UUID) {
        guard let rule = rules.first(where: { $0.id == id }) else { return }
        for ref in rule.sourceRefs {
            if case .watchPath(let pathID) = ref {
                pathIdsInOrder.removeAll { $0 == pathID }
            }
        }
        rules.removeAll { $0.id == id }
    }

    // MARK: - XML / form sync

    private func pickProgram() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            program = url.path
        }
    }

    private func loadXmlFromCurrentState() {
        if let data = try? PropertyListSerialization.data(
            fromPropertyList: currentRootDictionary(),
            format: .xml,
            options: 0
        ), let string = String(data: data, encoding: .utf8) {
            xmlText = string
        } else if let existingItem {
            xmlText = (try? plistService.readXml(from: existingItem.plistURL)) ?? ""
        } else {
            xmlText = ""
        }
        validateXmlText()
    }

    private func syncFormFromXmlIfPossible() {
        formDisabledReason = nil
        switch plistService.validateXml(xmlText) {
        case .failure:
            formDisabledReason = String(localized: "This plist contains keys not supported by the form editor. Please edit in XML mode.")
        case .success(let dict):
            if let reason = plistService.formIncompatibilityReason(for: dict) {
                formDisabledReason = reason
                return
            }
            applyManagedFieldsFromDictionary(dict)
            adoptRules(from: dict)
        }
    }

    private func adoptRules(from dict: [String: Any]) {
        // Existing edit session: never re-init from in-memory bytes (would corrupt disk hash).
        if var existing = session {
            do {
                try existing.replacingRootPreservingDiskBaseline(dict)
                session = existing
                rules = existing.rules
                pathIdsInOrder = existing.pathIdsInOrder
            } catch {
                applyProjectedRulesOnly(from: dict)
            }
            return
        }

        // Existing item without session: open from disk first to capture hash, then adopt.
        if let item = existingItem {
            if var opened = try? TriggerDocumentSession(url: item.plistURL) {
                do {
                    try opened.replacingRootPreservingDiskBaseline(dict)
                    session = opened
                    rules = opened.rules
                    pathIdsInOrder = opened.pathIdsInOrder
                } catch {
                    session = opened
                    applyProjectedRulesOnly(from: dict)
                }
                return
            }
            applyProjectedRulesOnly(from: dict)
            return
        }

        // New agent only - no on-disk baseline.
        if let adopted = try? TriggerDocumentSession(root: dict, url: nil) {
            session = adopted
            rules = adopted.rules
            pathIdsInOrder = adopted.pathIdsInOrder
        } else {
            applyProjectedRulesOnly(from: dict)
            session = nil
        }
    }

    private func applyProjectedRulesOnly(from dict: [String: Any]) {
        let native = TriggerCompiler.parseNative(from: dict)
        let projected = TriggerCompiler.project(native)
        rules = projected
        pathIdsInOrder = projected.flatMap { rule in
            rule.sourceRefs.compactMap { ref -> UUID? in
                if case .watchPath(let id) = ref { return id }
                return nil
            }
        }
    }

    private func reloadSessionFromDisk() {
        guard let existingItem else { return }
        do {
            let opened = try TriggerDocumentSession(url: existingItem.plistURL)
            session = opened
            rules = opened.rules
            pathIdsInOrder = opened.pathIdsInOrder
            applyManagedFieldsFromDictionary(opened.root)
            formDisabledReason = plistService.formIncompatibilityReason(for: opened.root)
            if editorMode == .xml {
                loadXmlFromCurrentState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkFormCompatibilityFromDisk() {
        guard editorMode == .form, let existingItem else { return }
        guard let dict = try? plistService.readDictionary(from: existingItem.plistURL) else { return }
        formDisabledReason = plistService.formIncompatibilityReason(for: dict)
    }

    private static func envRows(from variables: [String: String]) -> [EnvVarRow] {
        variables.keys.sorted().map { EnvVarRow(key: $0, value: variables[$0] ?? "") }
    }

    private var environmentVariablesFromRows: [String: String] {
        envVarRows.reduce(into: [:]) { result, row in
            let key = row.key.trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { return }
            result[key] = row.value
        }
    }

    private func applyManagedFieldsFromDictionary(_ dict: [String: Any]) {
        if let l = dict["Label"] as? String { label = l }

        if let args = dict["ProgramArguments"] as? [String], !args.isEmpty {
            program = args[0]
            argumentsText = args.dropFirst().joined(separator: "\n")
        } else if let prog = dict["Program"] as? String {
            program = prog
            argumentsText = ""
        }

        workingDirectory = dict["WorkingDirectory"] as? String ?? ""
        runAtLoad = dict["RunAtLoad"] as? Bool ?? false
        keepAlive = dict["KeepAlive"] as? Bool ?? false
        stdoutPath = dict["StandardOutPath"] as? String ?? ""
        stderrPath = dict["StandardErrorPath"] as? String ?? ""
        envVarRows = Self.envRows(from: plistService.parseEnvironmentVariables(dict["EnvironmentVariables"]))
    }

    private func applyManagedFields(to root: inout [String: Any]) {
        root["Label"] = label
        let args = argumentsText.components(separatedBy: "\n").filter { !$0.isEmpty }
        if args.isEmpty {
            root["Program"] = program
            root.removeValue(forKey: "ProgramArguments")
        } else {
            root["ProgramArguments"] = [program] + args
            root.removeValue(forKey: "Program")
        }

        if workingDirectory.isEmpty {
            root.removeValue(forKey: "WorkingDirectory")
        } else {
            root["WorkingDirectory"] = workingDirectory
        }

        let env = environmentVariablesFromRows
        if env.isEmpty {
            root.removeValue(forKey: "EnvironmentVariables")
        } else {
            root["EnvironmentVariables"] = env
        }

        if stdoutPath.isEmpty {
            root.removeValue(forKey: "StandardOutPath")
        } else {
            root["StandardOutPath"] = stdoutPath
        }
        if stderrPath.isEmpty {
            root.removeValue(forKey: "StandardErrorPath")
        } else {
            root["StandardErrorPath"] = stderrPath
        }

        if runAtLoad {
            root["RunAtLoad"] = true
        } else {
            root.removeValue(forKey: "RunAtLoad")
        }
        if keepAlive {
            root["KeepAlive"] = true
        } else {
            root.removeValue(forKey: "KeepAlive")
        }
    }

    private func buildRootFromFormFields() -> [String: Any] {
        var root: [String: Any] = [:]
        applyManagedFields(to: &root)
        return root
    }

    private func currentRootDictionary() -> [String: Any] {
        if var working = session {
            applyManagedFields(to: &working.root)
            working.rules = rules
            working.pathIdsInOrder = pathIdsInOrder
            working.applyTriggerRulesToRoot()
            return working.root
        }
        var root = buildRootFromFormFields()
        let emptyNative = TriggerCompiler.parseNative(from: [:])
        root = TriggerCompiler.applyTriggers(
            to: root,
            native: emptyNative,
            rules: rules,
            pathIdsInOrder: pathIdsInOrder
        )
        return root
    }

    private func validateXmlText() {
        switch plistService.validateXml(xmlText) {
        case .success:
            xmlError = nil
        case .failure(let err):
            xmlError = err.localizedDescription
        }
    }

    private var saveWouldWritePlist: Bool {
        guard editorMode == .form else { return true }
        if let session {
            let current = currentRootDictionary()
            return !NSDictionary(dictionary: current).isEqual(to: session.openedRoot)
        }
        return true
    }

    /// Shown when saving would rewrite a loaded job’s plist while RunAtLoad is enabled.
    private var runAtLoadSaveWarningVisible: Bool {
        runAtLoad && existingItem?.isLoaded == true && saveWouldWritePlist
    }

    private func requestSave() {
        if runAtLoadSaveWarningVisible {
            showRunAtLoadSaveConfirm = true
        } else {
            saveItem()
        }
    }

    private func saveItem() {
        let scope = existingItem?.scope ?? defaultScope

        if editorMode == .xml {
            guard case .success(let dict) = plistService.validateXml(xmlText),
                  let label = dict["Label"] as? String else {
                errorMessage = xmlError ?? String(localized: "Invalid plist")
                return
            }
            let plistURL = existingItem?.plistURL ??
                scope.directoryURL.appendingPathComponent("\(label).plist")
            do {
                try store.saveRawXml(xmlText, to: plistURL, scope: scope)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            return
        }

        do {
            if let existing = existingItem {
                // Existing agents always target the original plist URL - never a rebuilt path.
                var working: TriggerDocumentSession
                if let s = session {
                    working = s
                } else {
                    working = try TriggerDocumentSession(url: existing.plistURL)
                    session = working
                }
                if try working.fileChangedOnDisk() {
                    showDiskChangedAlert = true
                    return
                }
                applyManagedFields(to: &working.root)
                working.rules = rules
                working.pathIdsInOrder = pathIdsInOrder
                working.applyTriggerRulesToRoot()
                try store.saveRoot(
                    working.root,
                    to: existing.plistURL,
                    scope: existing.scope,
                    openedRoot: working.openedRoot
                )
            } else if var working = session {
                // New agent that already has an in-memory session (e.g. after XML sync).
                applyManagedFields(to: &working.root)
                working.rules = rules
                working.pathIdsInOrder = pathIdsInOrder
                working.applyTriggerRulesToRoot()
                let url = scope.directoryURL.appendingPathComponent("\(label).plist")
                try store.saveRoot(
                    working.root,
                    to: url,
                    scope: scope,
                    openedRoot: nil
                )
            } else {
                // Brand-new agent: build root + apply triggers from empty native.
                var root = buildRootFromFormFields()
                let emptyNative = TriggerCompiler.parseNative(from: [:])
                root = TriggerCompiler.applyTriggers(
                    to: root,
                    native: emptyNative,
                    rules: rules,
                    pathIdsInOrder: pathIdsInOrder
                )
                let url = scope.directoryURL.appendingPathComponent("\(label).plist")
                try store.saveRoot(root, to: url, scope: scope, openedRoot: nil)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func describePlistValue(_ value: Any) -> String {
        if let data = try? PropertyListSerialization.data(
            fromPropertyList: value, format: .xml, options: 0
        ),
           let string = String(data: data, encoding: .utf8) {
            let trimmed = string
                .replacingOccurrences(of: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>", with: "")
                .replacingOccurrences(
                    of: "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
                    with: ""
                )
                .replacingOccurrences(of: "<plist version=\"1.0\">", with: "")
                .replacingOccurrences(of: "</plist>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed
        }
        return String(describing: value)
    }
}

// MARK: - Private helpers

private enum EditorMode: String, CaseIterable {
    case form
    case xml
}

private enum IntervalUnit: String, CaseIterable, Identifiable, Hashable {
    case seconds
    case minutes
    case hours
    case days

    var id: String { rawValue }

    var secondsMultiplier: Int {
        switch self {
        case .seconds: return 1
        case .minutes: return 60
        case .hours: return 3_600
        case .days: return 86_400
        }
    }

    var localizedName: LocalizedStringKey {
        switch self {
        case .seconds: return "Seconds"
        case .minutes: return "Minutes"
        case .hours: return "Hours"
        case .days: return "Days"
        }
    }

    /// Prefer the largest fixed unit that divides evenly (300 → 5 minutes).
    static func split(seconds: Int) -> (amount: Int, unit: IntervalUnit) {
        let value = max(seconds, 1)
        for unit: IntervalUnit in [.days, .hours, .minutes] where value % unit.secondsMultiplier == 0 {
            return (value / unit.secondsMultiplier, unit)
        }
        return (value, .seconds)
    }
}

/// Month selection for monthly rules. Values are launchd Month 1…12.
private enum MonthSelectionMode: Hashable {
    case all
    case quarter
    case halfYear
    case custom

    init(months: Set<Int>?) {
        guard let months else {
            self = .all
            return
        }
        if months == Set([1, 4, 7, 10]) {
            self = .quarter
        } else if months == Set([1, 7]) {
            self = .halfYear
        } else {
            self = .custom
        }
    }
}

private struct EnvVarRow: Identifiable {
    let id = UUID()
    var key: String
    var value: String

    init(key: String = "", value: String = "") {
        self.key = key
        self.value = value
    }
}
