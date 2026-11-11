import AppKit
import SwiftUI

extension Notification.Name {
    static let showAbout = Notification.Name("showAbout")
}

@main
struct BootayarApp: App {
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 500)
                .tint(BootayarTheme.indigo)
                .environment(\.locale, lang.locale)
                .preferredColorScheme(theme.colorScheme)
                .onAppear {
                    theme.applyAppearance()
                }
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
            CommandMenu(L("Theme")) {
                Button(theme.currentTheme == .normal ? "✓ \(L("Normal Theme"))" : L("Normal Theme")) {
                    theme.setTheme(.normal)
                }
                Button(theme.currentTheme == .dark ? "✓ \(L("Dark Theme"))" : L("Dark Theme")) {
                    theme.setTheme(.dark)
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
