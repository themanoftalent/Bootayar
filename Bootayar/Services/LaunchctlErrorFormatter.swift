import Foundation

enum LaunchctlErrorFormatter {
    static func message(operation: String, detail: String) -> String {
        let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return String(localized: "\(operation) failed")
        }
        let hint = friendlyHint(for: trimmed)
        if let hint {
            return String(localized: "\(operation) failed: \(hint)\n\n\(trimmed)")
        }
        return String(localized: "\(operation) failed: \(trimmed)")
    }

    private static func friendlyHint(for detail: String) -> String? {
        let lower = detail.lowercased()
        if lower.contains("input/output error") || lower.contains("operation not permitted") {
            return String(localized: "Insufficient permissions or path is inaccessible")
        }
        if lower.contains("no such file") || lower.contains("not found") {
            return String(localized: "File or path does not exist")
        }
        if lower.contains("service already loaded") || lower.contains("already loaded") {
            return String(localized: "Service is already loaded")
        }
        if lower.contains("not loaded") || lower.contains("no such process") {
            return String(localized: "Service is not loaded or already stopped")
        }
        if lower.contains("bootstrap failed") {
            return String(localized: "Cannot load plist; check syntax and file path")
        }
        if lower.contains("permission denied") {
            return String(localized: "Permission denied")
        }
        return nil
    }
}

extension ShellError {
    var launchctlUserMessage: String {
        if case .nonZeroExit(_, let output) = self {
            return output
        }
        return localizedDescription
    }
}
