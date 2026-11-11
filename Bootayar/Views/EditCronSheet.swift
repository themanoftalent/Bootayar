import SwiftUI

struct EditCronSheet: View {
    let existingJob: CronJob?
    let scope: CrontabScope
    @ObservedObject var store: CrontabStore
    @Binding var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    @State private var preset: SchedulePreset
    @State private var minute: String
    @State private var hour: String
    @State private var dayOfMonth: String
    @State private var month: String
    @State private var weekday: String
    @State private var runAsUser: String
    @State private var command: String
    @State private var isEnabled: Bool

    init(
        existingJob: CronJob?,
        scope: CrontabScope,
        store: CrontabStore,
        errorMessage: Binding<String?>
    ) {
        self.existingJob = existingJob
        self.scope = existingJob?.scope ?? scope
        self.store = store
        _errorMessage = errorMessage

        let job = existingJob
        _minute = State(initialValue: job?.minute ?? "0")
        _hour = State(initialValue: job?.hour ?? "8")
        _dayOfMonth = State(initialValue: job?.dayOfMonth ?? "*")
        _month = State(initialValue: job?.month ?? "*")
        _weekday = State(initialValue: job?.weekday ?? "*")
        _runAsUser = State(initialValue: job?.runAsUser ?? NSUserName())
        _command = State(initialValue: job?.command ?? "")
        _isEnabled = State(initialValue: job?.isEnabled ?? true)
        _preset = State(initialValue: SchedulePreset.detect(
            minute: job?.minute ?? "0",
            hour: job?.hour ?? "8",
            dayOfMonth: job?.dayOfMonth ?? "*",
            month: job?.month ?? "*",
            weekday: job?.weekday ?? "*"
        ))
    }

    var body: some View {
        Form {
            Section(L("Schedule")) {
                Picker(L("Frequency"), selection: $preset) {
                    ForEach(SchedulePreset.allCases, id: \.self) { value in
                        Text(value.title).tag(value)
                    }
                }
                .onChange(of: preset) { _, newValue in
                    applyPreset(newValue)
                }

                switch preset {
                case .everyMinute:
                    EmptyView()
                case .hourly:
                    StepperField(title: "Minutes", value: $minute, range: 0...59)
                case .daily:
                    StepperField(title: "Hours", value: $hour, range: 0...23)
                    StepperField(title: "Minutes", value: $minute, range: 0...59)
                case .weekly:
                    Picker(L("Weekdays"), selection: $weekday) {
                        ForEach(WeekdayOption.allCases) { option in
                            Text(option.title).tag(option.value)
                        }
                    }
                    StepperField(title: "Hours", value: $hour, range: 0...23)
                    StepperField(title: "Minutes", value: $minute, range: 0...59)
                case .monthly:
                    StepperField(title: "Day of Month", value: $dayOfMonth, range: 1...31)
                    StepperField(title: "Hours", value: $hour, range: 0...23)
                    StepperField(title: "Minutes", value: $minute, range: 0...59)
                case .custom:
                    TextField("Minutes", text: $minute)
                    TextField("Hours", text: $hour)
                    TextField("Day", text: $dayOfMonth)
                    TextField("Month", text: $month)
                    TextField("Weekdays", text: $weekday)
                }

                Text(previewSchedule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(L("Command")) {
                if scope == .system {
                    TextField("Run as User", text: $runAsUser)
                        .font(.system(.body, design: .monospaced))
                }
                TextField("Command to execute", text: $command, axis: .vertical)
                    .lineLimit(2...6)
                    .font(.system(.body, design: .monospaced))
                Toggle(L("Enable"), isOn: $isEnabled)
            }

            if scope.requiresPrivilege {
                Section {
                    Text(L("Administrator password required when saving system crontab."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 460, minHeight: 360)
        .navigationTitle(existingJob == nil ? "New Cron Job" : "Edit Cron Job")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L("Cancel")) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L("Save")) { save() }
                    .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        let hasUser = scope == .user || !runAsUser.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasUser &&
        !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        [minute, hour, dayOfMonth, month, weekday].allSatisfy { !$0.isEmpty }
    }

    private var previewSchedule: String {
        CronScheduleDescriber.describe(
            minute: minute,
            hour: hour,
            dayOfMonth: dayOfMonth,
            month: month,
            weekday: weekday
        )
    }

    private func applyPreset(_ preset: SchedulePreset) {
        switch preset {
        case .everyMinute:
            minute = "*"; hour = "*"; dayOfMonth = "*"; month = "*"; weekday = "*"
        case .hourly:
            hour = "*"; dayOfMonth = "*"; month = "*"; weekday = "*"
            if minute == "*" { minute = "0" }
        case .daily:
            dayOfMonth = "*"; month = "*"; weekday = "*"
            if hour == "*" { hour = "8" }
            if minute == "*" { minute = "0" }
        case .weekly:
            dayOfMonth = "*"; month = "*"
            if weekday == "*" { weekday = "1" }
            if hour == "*" { hour = "8" }
            if minute == "*" { minute = "0" }
        case .monthly:
            month = "*"; weekday = "*"
            if dayOfMonth == "*" { dayOfMonth = "1" }
            if hour == "*" { hour = "8" }
            if minute == "*" { minute = "0" }
        case .custom:
            break
        }
    }

    private func save() {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUser = runAsUser.trimmingCharacters(in: .whitespacesAndNewlines)
        let job = CronJob(
            id: existingJob?.id ?? UUID(),
            scope: scope,
            minute: minute,
            hour: hour,
            dayOfMonth: dayOfMonth,
            month: month,
            weekday: weekday,
            runAsUser: scope == .system ? trimmedUser : nil,
            command: trimmedCommand,
            isEnabled: isEnabled
        )
        do {
            try store.save(job: job, replacing: existingJob?.id)
            dismiss()
        } catch PrivilegeError.cancelled {
            // user dismissed admin dialog
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum SchedulePreset: CaseIterable {
    case everyMinute
    case hourly
    case daily
    case weekly
    case monthly
    case custom

    var title: String {
        switch self {
        case .everyMinute: return "Every minute"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .custom: return "Custom"
        }
    }

    static func detect(
        minute: String,
        hour: String,
        dayOfMonth: String,
        month: String,
        weekday: String
    ) -> SchedulePreset {
        if minute == "*" && hour == "*" && dayOfMonth == "*" && month == "*" && weekday == "*" {
            return .everyMinute
        }
        if hour == "*" && dayOfMonth == "*" && month == "*" && weekday == "*" {
            return .hourly
        }
        if dayOfMonth == "*" && month == "*" && weekday == "*" {
            return .daily
        }
        if dayOfMonth == "*" && month == "*" && weekday != "*" {
            return .weekly
        }
        if month == "*" && weekday == "*" && dayOfMonth != "*" {
            return .monthly
        }
        return .custom
    }
}

private struct WeekdayOption: Identifiable {
    let value: String
    let title: String
    var id: String { value }

    static let allCases: [WeekdayOption] = [
        WeekdayOption(value: "1", title: "Mon"),
        WeekdayOption(value: "2", title: "Tue"),
        WeekdayOption(value: "3", title: "Wed"),
        WeekdayOption(value: "4", title: "Thu"),
        WeekdayOption(value: "5", title: "Fri"),
        WeekdayOption(value: "6", title: "Sat"),
        WeekdayOption(value: "0", title: "Sun"),
    ]
}

private struct StepperField: View {
    let title: String
    @Binding var value: String
    let range: ClosedRange<Int>

    private var intValue: Int {
        Int(value) ?? range.lowerBound
    }

    var body: some View {
        Stepper(value: Binding(
            get: { intValue },
            set: { value = String($0) }
        ), in: range) {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}
