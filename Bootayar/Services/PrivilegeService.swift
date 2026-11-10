import Foundation

enum PrivilegeError: LocalizedError {
    case cancelled
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .cancelled: return String(localized: "Operation cancelled")
        case .executionFailed(let msg): return String(localized: "Execution failed: \(msg)")
        }
    }
}

struct PrivilegeService {
    func run(_ shellCommand: String) throws {
        let escaped = shellCommand
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let source = "do shell script \"\(escaped)\" with administrator privileges"
        var errorDict: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&errorDict)
        guard let err = errorDict else { return }
        let code = err[NSAppleScript.errorNumber] as? Int ?? 0
        if code == -128 { throw PrivilegeError.cancelled }
        let msg = err[NSAppleScript.errorMessage] as? String ?? "\(err)"
        throw PrivilegeError.executionFailed(msg)
    }
}
