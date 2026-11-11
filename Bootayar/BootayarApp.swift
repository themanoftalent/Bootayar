import AppKit
import SwiftUI

extension Notification.Name {
    static let showAbout = Notification.Name("showAbout")
}

@main
struct BootayarApp: App {
    @ObservedObject private var lang = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 500)
                .tint(BootayarTheme.indigo)
                .environment(\.locale, lang.locale)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appInfo) {
                Button(L("About Bootayar")) {
                    NotificationCenter.default.post(name: .showAbout, object: nil)
                }
            }
            CommandMenu(L("Language")) {
                Button(lang.currentLanguage == "en" ? "✓ English" : "English") {
                    lang.setLanguage("en")
                }
                Button(lang.currentLanguage == "tr" ? "✓ Türkçe" : "Türkçe") {
                    lang.setLanguage("tr")
                }
            }
            CommandGroup(replacing: .help) {
                Button(L("Bootayar Help")) {
                    if let url = URL(string: "https://github.com/themanoftalent/Bootayar#readme") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
