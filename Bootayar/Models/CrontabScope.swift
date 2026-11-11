import Foundation
import SwiftUI

enum CrontabScope: String, CaseIterable, Hashable {
    case user
    case system

    var displayName: String {
        switch self {
        case .user: return L("User Crontab")
        case .system: return L("System Crontab")
        }
    }

    var sectionTitle: String {
        switch self {
        case .user: return L("User Crontab")
        case .system: return L("System Crontab")
        }
    }

    var sectionSubtitle: String {
        switch self {
        case .user: return L("crontab -l")
        case .system: return L("/etc/crontab")
        }
    }

    var systemImage: String {
        switch self {
        case .user: return L("person.circle")
        case .system: return L("server.rack")
        }
    }

    var newJobMenuTitle: String {
        switch self {
        case .user: return L("New User Cron Job")
        case .system: return L("New System Cron Job")
        }
    }

    var sourceDescription: String {
        switch self {
        case .user: return L("crontab -l")
        case .system: return L("/etc/crontab")
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
