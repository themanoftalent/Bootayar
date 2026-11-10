import SwiftUI

enum PendingOperation: Equatable {
    case starting
    case stopping
    case loading
    case unloading
    case enabling
    case restarting

    var localizedLabel: LocalizedStringKey {
        switch self {
        case .starting:  return "Starting…"
        case .stopping:  return "Stopping…"
        case .loading:   return "Loading…"
        case .unloading: return "Unloading…"
        case .enabling:  return "Enabling…"
        case .restarting: return "Restarting…"
        }
    }
}
