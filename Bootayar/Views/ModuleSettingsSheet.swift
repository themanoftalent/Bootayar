import SwiftUI

struct ModuleSettingsSheet: View {
    @ObservedObject var moduleSettings: ModuleSettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var showMinimumModuleAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("Choose Your Tools"))
                    .font(.headline)
                Spacer()
                Button(L("Show All")) {
                    moduleSettings.enableAll()
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            Form {
                Section {
                    Text(L("Keep at least one tool selected. Hidden tools stop checking for updates in the background."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(L("Display & Scanning")) {
                    ForEach(AppModule.allCases) { module in
                        Toggle(isOn: binding(for: module)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(module.title)
                                Text(module.settingsDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button(L("Done")) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 420, height: 420)
        .alert(L("Keep At Least One Module"), isPresented: $showMinimumModuleAlert) {
            Button(L("OK"), role: .cancel) {}
        } message: {
            Text(L("Select at least one tool to continue."))
        }
    }

    private func binding(for module: AppModule) -> Binding<Bool> {
        Binding(
            get: { moduleSettings.isEnabled(module) },
            set: { newValue in
                if newValue {
                    _ = moduleSettings.setEnabled(module, enabled: true)
                } else if !moduleSettings.setEnabled(module, enabled: false) {
                    showMinimumModuleAlert = true
                }
            }
        )
    }
}
