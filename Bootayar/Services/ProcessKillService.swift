import Foundation

enum ProcessKillError: LocalizedError {
    case notKillable(pid: Int32)
    case signalFailed(pid: Int32, errno: Int32)

    var errorDescription: String? {
        switch self {
        case .notKillable(let pid):
            return L("Cannot terminate PID \(pid): permission denied")
        case .signalFailed(let pid, _):
            return L("Cannot send signal to PID \(pid)")
        }
    }
}

struct ProcessKillService: Sendable {
    static func isKillable(pid: Int32) -> Bool { Darwin.kill(pid, 0) == 0 }

    func kill(pid: Int32, termTimeoutSeconds: Double = 5) async throws {
        guard Self.isKillable(pid: pid) else { throw ProcessKillError.notKillable(pid: pid) }
        if Darwin.kill(pid, SIGTERM) != 0 { throw ProcessKillError.signalFailed(pid: pid, errno: errno) }
        let deadline = Date().addingTimeInterval(termTimeoutSeconds)
        while Date() < deadline {
            if !Self.isKillable(pid: pid) { return }
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        if Self.isKillable(pid: pid) { Darwin.kill(pid, SIGKILL) }
    }
}
