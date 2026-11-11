import Foundation
import SwiftUI

enum AppModule: String, CaseIterable, Identifiable, Codable, Hashable {
    case agents
    case crontab
    case loginItems
    case services

    var id: String { rawValue }

    var sidebarSelection: SidebarSelection {
        switch self {
        case .agents: return .agents
        case .crontab: return .crontab
        case .loginItems: return .loginItems
        case .services: return .services
        }
    }

    var title: String {
        switch self {
        case .agents: return L("Startup Tasks")
        case .crontab: return L("Scheduled Tasks")
        case .loginItems: return L("Login Items")
        case .services: return L("Services")
        }
    }

    var subtitle: String {
        switch self {
        case .agents: return L("User, system, and Homebrew tasks")
        case .crontab: return L("Personal and system schedules")
        case .loginItems: return L("Manage apps that open at login")
        case .services: return L("Local ports and services")
        }
    }

    var systemImage: String {
        switch self {
        case .agents: return L("list.bullet.rectangle")
        case .crontab: return L("clock")
        case .loginItems: return L("key.fill")
        case .services: return L("bolt.fill")
        }
    }

    var settingsDescription: String {
        switch self {
        case .agents: return L("Find background startup tasks and Homebrew services")
        case .crontab: return L("Find personal and system scheduled tasks")
        case .loginItems: return L("Open the login items guide and System Settings")
        case .services: return L("Find local network ports and running services")
        }
    }
}

enum AppLinks {
    static let helpURL = URL(string: "https://github.com/themanoftalent/Bootayar#readme")!
}
