import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    static let homebrewCommand = GitHubRelease.homebrewUpgradeCommand

    @Published var pendingRelease: GitHubRelease?
    @Published private(set) var isChecking = false
    @Published var statusMessage: String?
    @Published var isUpToDate = false

    private let defaults: UserDefaults
    private let releaseService: @Sendable (URLSession) async -> GitHubRelease?

    private enum Keys {
        static let lastUpdateCheckDate = "lastUpdateCheckDate"
        static let skippedUpdateVersion = "skippedUpdateVersion"
    }

    init(
        defaults: UserDefaults = .standard,
        releaseService: @escaping @Sendable (URLSession) async -> GitHubRelease? = GitHubReleaseService.fetchLatest
    ) {
        self.defaults = defaults
        self.releaseService = releaseService
    }

    var currentVersion: AppVersion { AppVersion.current }

    func checkIfNeeded(session: URLSession = .shared) {
        guard !isChecking else { return }
        if let lastCheck = defaults.object(forKey: Keys.lastUpdateCheckDate) as? Date,
           Calendar.current.isDateInToday(lastCheck) {
            return
        }
        performCheck(session: session, isManual: false)
    }

    func checkNow(session: URLSession = .shared) {
        guard !isChecking else { return }
        performCheck(session: session, isManual: true)
    }

    func skipVersion(_ version: AppVersion) {
        defaults.set(version.displayString, forKey: Keys.skippedUpdateVersion)
        pendingRelease = nil
    }

    func dismissForLater() {
        pendingRelease = nil
    }

    private func performCheck(session: URLSession, isManual: Bool) {
        isChecking = true
        if isManual {
            statusMessage = nil
            isUpToDate = false
        }
        Task {
            let release = await releaseService(session)
            defaults.set(Date(), forKey: Keys.lastUpdateCheckDate)
            isChecking = false

            guard let release else {
                if isManual {
                    statusMessage = "Unable to check GitHub releases right now."
                    isUpToDate = false
                }
                return
            }

            let current = AppVersion.current
            guard release.version.isNewer(than: current) else {
                if isManual {
                    statusMessage = "Bootayar v\(current.displayString) is up to date."
                    isUpToDate = true
                }
                return
            }

            if !isManual {
                let skipped = defaults.string(forKey: Keys.skippedUpdateVersion)
                if skipped == release.version.displayString { return }
            }

            statusMessage = "New version v\(release.version.displayString) available!"
            isUpToDate = false
            pendingRelease = release
        }
    }
}
