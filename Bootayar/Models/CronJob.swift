import Foundation

struct CronJob: Identifiable, Hashable {
    let id: UUID
    var scope: CrontabScope
    var minute: String
    var hour: String
    var dayOfMonth: String
    var month: String
    var weekday: String
    var runAsUser: String?
    var command: String
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        scope: CrontabScope = .user,
        minute: String,
        hour: String,
        dayOfMonth: String,
        month: String,
        weekday: String,
        runAsUser: String? = nil,
        command: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.scope = scope
        self.minute = minute
        self.hour = hour
        self.dayOfMonth = dayOfMonth
        self.month = month
        self.weekday = weekday
        self.runAsUser = runAsUser
        self.command = command
        self.isEnabled = isEnabled
    }

    var scheduleFields: [String] {
        [minute, hour, dayOfMonth, month, weekday]
    }

    var scheduleDescription: String {
        CronScheduleDescriber.describe(
            minute: minute,
            hour: hour,
            dayOfMonth: dayOfMonth,
            month: month,
            weekday: weekday
        )
    }
}

enum CrontabLine: Identifiable, Hashable {
    case blank(id: UUID)
    case comment(id: UUID, text: String)
    case environment(id: UUID, key: String, value: String)
    case job(CronJob)
    case raw(id: UUID, line: String)

    var id: UUID {
        switch self {
        case .blank(let id), .comment(let id, _), .environment(let id, _, _), .raw(let id, _):
            return id
        case .job(let job):
            return job.id
        }
    }
}

enum CronScheduleDescriber {
    static func describe(
        minute: String,
        hour: String,
        dayOfMonth: String,
        month: String,
        weekday: String
    ) -> String {
        let m = minute, h = hour, dom = dayOfMonth, mon = month, dow = weekday

        if m == "*" && h == "*" && dom == "*" && mon == "*" && dow == "*" {
            return String(localized: "Every minute")
        }
        if m == "0" && h == "*" && dom == "*" && mon == "*" && dow == "*" {
            return String(localized: "Every hour on the hour")
        }
        if dom == "*" && mon == "*" && dow == "*" && h != "*" && m != "*" {
            return String(localized: "Daily at \(h):\(pad(m))")
        }
        if dom == "*" && mon == "*" && h != "*" && m != "*" && dow != "*" {
            let day = weekdayName(dow) ?? "Weekday \(dow)"
            return String(localized: "Every \(day) at \(h):\(pad(m))")
        }
        if dow == "*" && mon == "*" && h != "*" && m != "*" && dom != "*" {
            return String(localized: "Monthly on day \(dom) at \(h):\(pad(m))")
        }
        return "\(m) \(h) \(dom) \(mon) \(dow)"
    }

    private static func pad(_ value: String) -> String {
        value.count == 1 ? "0\(value)" : value
    }

    private static func weekdayName(_ value: String) -> String? {
        switch value {
        case "0", "7": return String(localized: "Sun")
        case "1": return String(localized: "Mon")
        case "2": return String(localized: "Tue")
        case "3": return String(localized: "Wed")
        case "4": return String(localized: "Thu")
        case "5": return String(localized: "Fri")
        case "6": return String(localized: "Sat")
        default: return nil
        }
    }
}
