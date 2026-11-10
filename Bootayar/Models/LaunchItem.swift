import Foundation
import SwiftUI

struct LaunchItem: Identifiable, Hashable {
    var id: String { label }
    var label: String
    var plistURL: URL
    var scope: Scope
    var program: String
    var programArguments: [String]
    var calendarIntervals: [CalendarInterval]
    var startInterval: Int?
    var watchPaths: [String]
    var runAtLoad: Bool
    var keepAlive: Bool
    var standardOutPath: String?
    var standardErrorPath: String?
    var workingDirectory: String?
    var environmentVariables: [String: String] = [:]
    var isLoaded: Bool
    var isDisabledByOverride: Bool = false
    var pid: Int?
    var lastExitCode: Int?
    // Trigger summary shown in list
    var triggerSummaryLines: [String] = []

    enum Scope: String, CaseIterable, Hashable {
        case userAgent    = "userAgent"
        case systemAgent  = "systemAgent"
        case systemDaemon = "systemDaemon"

        var displayName: String {
            switch self {
            case .userAgent, .systemAgent: return "LaunchAgent"
            case .systemDaemon:            return "LaunchDaemon"
            }
        }

        var directoryHint: LocalizedStringKey {
            switch self {
            case .userAgent:    return "User · ~/Library"
            case .systemAgent:  return "Global · /Library"
            case .systemDaemon: return "System · /Library"
            }
        }

        var sectionTitle: LocalizedStringKey {
            switch self {
            case .userAgent:    return "User Agents"
            case .systemAgent:  return "Global Agents"
            case .systemDaemon: return "LaunchDaemons"
            }
        }

        var sectionSubtitle: LocalizedStringKey {
            switch self {
            case .userAgent:    return "~/Library/LaunchAgents"
            case .systemAgent:  return "/Library/LaunchAgents"
            case .systemDaemon: return "/Library/LaunchDaemons"
            }
        }

        var systemImage: String {
            switch self {
            case .userAgent:    return "person.circle"
            case .systemAgent:  return "gearshape.circle"
            case .systemDaemon: return "server.rack"
            }
        }

        var newAgentMenuTitle: LocalizedStringKey {
            switch self {
            case .userAgent:    return "New User Agent"
            case .systemAgent:  return "New Global Agent"
            case .systemDaemon: return "New LaunchDaemon"
            }
        }

        var directoryURL: URL {
            switch self {
            case .userAgent:
                return FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/LaunchAgents")
            case .systemAgent:
                return URL(fileURLWithPath: "/Library/LaunchAgents")
            case .systemDaemon:
                return URL(fileURLWithPath: "/Library/LaunchDaemons")
            }
        }

        var requiresPrivilege: Bool { self != .userAgent }
    }

    struct CalendarInterval: Hashable {
        var weekday: Int?
        var hour: Int?
        var minute: Int?
        var day: Int?
        var month: Int?

        init(
            weekday: Int? = nil,
            hour: Int? = nil,
            minute: Int? = nil,
            day: Int? = nil,
            month: Int? = nil
        ) {
            self.weekday = weekday
            self.hour = hour
            self.minute = minute
            self.day = day
            self.month = month
        }
    }

    // Extra launch keys shown in summary
    static let passthroughLaunchKeys: Set<String> = [
        "QueueDirectories", "StartOnMount", "Sockets",
    ]

    // Build summary strings from plist dict
    static func summaryLines(from root: [String: Any], runAtLoad: Bool) -> [String] {
        let native = TriggerCompiler.parseNative(from: root)
        let rules = TriggerCompiler.project(native)
        var lines: [String] = rules.map { line(for: $0.kind) }

        let passthroughCount = passthroughLaunchKeys.filter { root[$0] != nil }.count
        if passthroughCount > 0 {
            lines.append(
                String(
                    format: String(localized: "+%lld other trigger conditions"),
                    locale: .current,
                    passthroughCount
                )
            )
        }

        if runAtLoad {
            lines.append(String(localized: "Run at Login"))
        }

        if lines.isEmpty {
            lines.append(String(localized: "No Automatic Trigger"))
        }
        return lines
    }

    private static func line(for kind: TriggerRuleKind) -> String {
        switch kind {
        case .daily(let hour, let minute):
            return "Daily \(timeString(hour: hour, minute: minute))"
        case .weekly(let weekdays, let hour, let minute):
            let days = formatWeekdays(weekdays)
            return "\(days) \(timeString(hour: hour, minute: minute))"
        case .monthly(let day, let hour, let minute, let months):
            let time = timeString(hour: hour, minute: minute)
            if let months, !months.isEmpty {
                let monthList = months.sorted().map(String.init).joined(separator: ",")
                return String(
                    format: String(localized: "Monthly · Month %@ · Day %lld at %@"),
                    locale: .current,
                    monthList, day, time
                )
            }
            return String(
                format: String(localized: "Monthly on day %lld at %@"),
                locale: .current,
                day, time
            )
        case .yearly(let month, let day, let hour, let minute):
            let time = timeString(hour: hour, minute: minute)
            return String(
                format: String(localized: "Yearly on %lld/%lld at %@"),
                locale: .current,
                month, day, time
            )
        case .interval(let seconds):
            return String(localized: "Every \(seconds)s")
        case .watchPath(let path):
            return String(localized: "Watch path: \(path)")
        case .customCalendar(let summary, let isMalformed):
            if isMalformed {
                return "Invalid Config: \(summary)"
            }
            return "Custom Calendar: \(summary)"
        }
    }

    private static func timeString(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    private static func formatWeekdays(_ weekdays: [Int]) -> String {
        let weekdayNames = [
            "",
            String(localized: "Mon"),
            String(localized: "Tue"),
            String(localized: "Wed"),
            String(localized: "Thu"),
            String(localized: "Fri"),
            String(localized: "Sat"),
            String(localized: "Sun"),
        ]
        let normalized = Array(Set(weekdays.map { $0 == 0 ? 7 : $0 }))
            .filter { (1...7).contains($0) }
            .sorted()
        guard !normalized.isEmpty else { return "" }
        let names = normalized.map { weekdayNames[$0] }
        if names.count >= 2 {
            let consecutive = zip(normalized, normalized.dropFirst()).allSatisfy { $1 - $0 == 1 }
            if consecutive {
                return "\(names.first!)–\(names.last!)"
            }
        }
        return names.joined(separator: ", ")
    }
}
