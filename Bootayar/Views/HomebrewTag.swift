import SwiftUI

struct HomebrewTag: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "mug.fill")
                .font(.system(size: 8.5, weight: .bold))
            Text(L("Brew"))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 6.5)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(BootayarTheme.amber.opacity(0.14))
        )
        .overlay(
            Capsule()
                .strokeBorder(BootayarTheme.amber.opacity(0.35), lineWidth: 1)
        )
        .foregroundStyle(BootayarTheme.amber)
    }
}
