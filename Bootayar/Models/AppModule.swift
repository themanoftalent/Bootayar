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

    var title: LocalizedStringKey {
        switch self {
        case .agents: return "Startup Tasks"
        case .crontab: return "Scheduled Tasks"
        case .loginItems: return "Login Items"
        case .services: return "Services"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .agents: return "User, system, and Homebrew tasks"
        case .crontab: return "Personal and system schedules"
        case .loginItems: return "Manage apps that open at login"
        case .services: return "Local ports and services"
        }
    }

    var systemImage: String {
        switch self {
        case .agents: return "list.bullet.rectangle"
        case .crontab: return "clock"
        case .loginItems: return "key.fill"
        case .services: return "bolt.fill"
        }
    }

    var settingsDescription: LocalizedStringKey {
        switch self {
        case .agents: return "Find background startup tasks and Homebrew services"
        case .crontab: return "Find personal and system scheduled tasks"
        case .loginItems: return "Open the login items guide and System Settings"
        case .services: return "Find local network ports and running services"
        }
    }
}

enum AppLinks {
    static let helpURL = URL(string: "https://github.com/themanoftalent/Bootayar#readme")!
}
