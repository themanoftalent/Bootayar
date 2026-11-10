import Foundation
import SwiftUI

enum HomebrewServiceScope: String, CaseIterable, Hashable {
    case user
    case root

    var sectionTitle: LocalizedStringKey {
        switch self {
        case .user: return "User Services"
        case .root: return "System Services"
        }
    }

    var sectionSubtitle: LocalizedStringKey {
        switch self {
        case .user: return "brew services · ~/Library/LaunchAgents"
        case .root: return "sudo brew services · /Library/LaunchDaemons"
        }
    }

    var systemImage: String {
        switch self {
        case .user: return "person.circle"
        case .root: return "server.rack"
        }
    }

    var requiresPrivilege: Bool { self == .root }
}
