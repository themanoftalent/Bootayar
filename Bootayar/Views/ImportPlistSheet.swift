import SwiftUI

struct ImportPlistSheet: View {
    let sourceURL: URL
    @ObservedObject var store: AgentStore
    @Binding var errorMessage: String?
    var onImported: (LaunchItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scope: LaunchItem.Scope = .userAgent
    @State private var inlineError: String?
    @State private var showOverwriteConfirm = false

    var body: some View {
        Form {
            Section(L("Import Into")) {
                Picker(L("Scope"), selection: $scope) {
                    ForEach(LaunchItem.Scope.allCases, id: \.self) { s in
                        Text(s.sectionTitle).tag(s)
                    }
                }
                Text(sourceURL.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let inlineError {
                Section {
                    Text(inlineError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 180)
        .navigationTitle(L("Import Plist"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L("Cancel")) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L("Import")) { importPlist(overwrite: false) }
            }
        }
        .confirmationDialog(L("File already exists. Overwrite?"),
            isPresented: $showOverwriteConfirm,
            titleVisibility: .visible
        ) {
            Button(L("Overwrite"), role: .destructive) { importPlist(overwrite: true) }
            Button(L("Cancel"), role: .cancel) {}
        }
    }

    private func importPlist(overwrite: Bool) {
        do {
            let item = try store.importPlist(from: sourceURL, scope: scope, overwrite: overwrite)
            onImported(item)
            dismiss()
        } catch PlistValidationError.invalidFormat(let message) {
            if message == L("File already exists") {
                showOverwriteConfirm = true
            } else {
                inlineError = message
            }
        } catch {
            inlineError = error.localizedDescription
        }
    }
}
