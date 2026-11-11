import SwiftUI

enum PendingOperation: Equatable {
    case starting
    case stopping
    case loading
    case unloading
    case enabling
    case restarting

    var localizedLabel: String {
        switch self {
        case .starting:  return L("Starting…")
        case .stopping:  return L("Stopping…")
        case .loading:   return L("Loading…")
        case .unloading: return L("Unloading…")
        case .enabling:  return L("Enabling…")
        case .restarting: return L("Restarting…")
        }
    }
}
