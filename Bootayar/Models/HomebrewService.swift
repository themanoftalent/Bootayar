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
        case .started: return L("Running")
        case .stopped: return L("Stopped")
        case .none: return L("Unregistered")
        case .error: return L("Error")
        case .unknown: return L("Unknown")
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
