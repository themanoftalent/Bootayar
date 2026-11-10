import AppKit
import SwiftUI

extension Notification.Name {
    static let showAbout = Notification.Name("showAbout")
}

@main
struct BootayarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 500)
                .tint(BootayarTheme.indigo)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appInfo) {
                Button("About Bootayar") {
                    NotificationCenter.default.post(name: .showAbout, object: nil)
                }
            }
            CommandGroup(replacing: .help) {
                Button("Bootayar Help") {
                    if let url = URL(string: "https://github.com/themanoftalent/Bootayar#readme") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
