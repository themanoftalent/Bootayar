import Foundation
import SwiftUI

enum CrontabScope: String, CaseIterable, Hashable {
    case user
    case system

    var displayName: String {
        switch self {
        case .user: return String(localized: "User Crontab")
        case .system: return String(localized: "System Crontab")
        }
    }

    var sectionTitle: LocalizedStringKey {
        switch self {
        case .user: return "User Crontab"
        case .system: return "System Crontab"
        }
    }

    var sectionSubtitle: LocalizedStringKey {
        switch self {
        case .user: return "crontab -l"
        case .system: return "/etc/crontab"
        }
    }

    var systemImage: String {
        switch self {
        case .user: return "person.circle"
        case .system: return "server.rack"
        }
    }

    var newJobMenuTitle: LocalizedStringKey {
        switch self {
        case .user: return "New User Cron Job"
        case .system: return "New System Cron Job"
        }
    }

    var sourceDescription: String {
        switch self {
        case .user: return "crontab -l"
        case .system: return "/etc/crontab"
        }
    }

    var requiresPrivilege: Bool { self == .system }

    var parserFormat: CrontabFormat {
        switch self {
        case .user: return .user
        case .system: return .system
        }
    }
}

enum CrontabFormat {
    case user
    case system
}
