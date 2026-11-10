import Foundation

enum HomebrewServiceStatus: String, Hashable {
    case started
    case stopped
    case none
    case error
    case unknown

    init(brewStatus: String) {
        switch brewStatus {
        case "started": self = .started
        case "stopped": self = .stopped
        case "none": self = .none
        case "error": self = .error
        default: self = .unknown
        }
    }

    var localizedName: String {
        switch self {
        case .started: return String(localized: "Running")
        case .stopped: return String(localized: "Stopped")
        case .none: return String(localized: "Unregistered")
        case .error: return String(localized: "Error")
        case .unknown: return String(localized: "Unknown")
        }
    }
}

struct HomebrewService: Identifiable, Hashable {
    var name: String
    var scope: HomebrewServiceScope
    var status: HomebrewServiceStatus
    var runAsUser: String?
    var plistPath: String?
    var exitCode: Int?

    var id: String { "\(scope.rawValue):\(name)" }
    var label: String { "homebrew.mxcl.\(name)" }

    var isRunning: Bool { status == .started }
    var isRegistered: Bool { status == .started || status == .stopped }
}
