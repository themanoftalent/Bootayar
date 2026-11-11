import AppKit
import SwiftUI

extension Notification.Name {
    static let showAbout = Notification.Name("showAbout")
}

@main
struct BootayarApp: App {
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 500)
                .tint(BootayarTheme.indigo)
                .environment(\.locale, Locale(identifier: appLanguage))
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
            CommandMenu("Language") {
                Button(appLanguage == "en" ? "✓ English" : "English") {
                    appLanguage = "en"
                    UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
                }
                Button(appLanguage == "tr" ? "✓ Türkçe" : "Türkçe") {
                    appLanguage = "tr"
                    UserDefaults.standard.set(["tr"], forKey: "AppleLanguages")
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
