import Foundation
import SwiftUI

enum SidebarSelection: Hashable {
    case agents
    case crontab
    case loginItems
    case services
    case about

    var appModule: AppModule? {
        switch self {
        case .agents: return .agents
        case .crontab: return .crontab
        case .loginItems: return .loginItems
        case .services: return .services
        case .about: return nil
        }
    }
}

enum AgentListFilter: Hashable {
    case all
    case homebrew
    case scope(LaunchItem.Scope)

    var chipTitle: LocalizedStringKey {
        switch self {
        case .all: return "All"
        case .homebrew: return "Homebrew"
        case .scope(let scope):
            switch scope {
            case .userAgent: return "User"
            case .systemAgent: return "Global"
            case .systemDaemon: return "Daemon"
            }
        }
    }
}
