import Foundation
import SwiftUI

enum HomebrewServiceScope: String, CaseIterable, Hashable {
    case user
    case root

    var sectionTitle: String {
        switch self {
        case .user: return L("User Services")
        case .root: return L("System Services")
        }
    }

    var sectionSubtitle: String {
        switch self {
        case .user: return L("brew services · ~/Library/LaunchAgents")
        case .root: return L("sudo brew services · /Library/LaunchDaemons")
        }
    }

    var systemImage: String {
        switch self {
        case .user: return L("person.circle")
        case .root: return L("server.rack")
        }
    }

    var requiresPrivilege: Bool { self == .root }
}
