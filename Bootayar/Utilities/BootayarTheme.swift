import AppKit
import SwiftUI

enum BootayarTheme {
    // Brand colors
    static let indigo = Color(red: 0.357, green: 0.310, blue: 0.965)          // #5B4FF6
    static let electricViolet = Color(red: 0.545, green: 0.361, blue: 0.965)  // #8B5CF6
    static let softViolet = Color(red: 0.655, green: 0.545, blue: 0.980)      // #A78BFA
    static let deepIndigo = Color(red: 0.239, green: 0.200, blue: 0.725)      // #3D33B9

    // Status colors
    static let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)         // #10B981
    static let amber = Color(red: 0.961, green: 0.620, blue: 0.043)           // #F59E0B
    static let crimson = Color(red: 0.937, green: 0.267, blue: 0.267)         // #EF4444
    static let loadedIndigo = Color(red: 0.388, green: 0.400, blue: 0.945)    // #6366F1
    static let neutralSlate = Color(nsColor: .tertiaryLabelColor)

    // MARK: - Gradients
    static let brandGradient = LinearGradient(
        colors: [indigo, electricViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleHeaderGradient = LinearGradient(
        colors: [
            indigo.opacity(0.14),
            electricViolet.opacity(0.06),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sidebarSelectionGradient = LinearGradient(
        colors: [indigo, electricViolet],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// Status badge

struct BootayarStatusBadge: View {
    let title: LocalizedStringKey
    let color: Color
    var isPulsing: Bool = false

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.6), radius: 3)
                .opacity(isPulsing ? (pulse ? 1.0 : 0.35) : 1.0)
                .animation(
                    isPulsing ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                    value: pulse
                )
            Text(title)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2.5)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(0.28), lineWidth: 1)
        )
        .onAppear { pulse = isPulsing }
        .onChange(of: isPulsing) { _, newValue in
            pulse = newValue
        }
    }
}

// Card row style

struct BootayarCardModifier: ViewModifier {
    var statusColor: Color = BootayarTheme.indigo
    var isExpanded: Bool = false
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    BootayarTheme.indigo.opacity(isHovered ? 0.06 : 0.02),
                                    BootayarTheme.electricViolet.opacity(isHovered ? 0.04 : 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(
                        isExpanded
                            ? BootayarTheme.indigo.opacity(0.45)
                            : (isHovered ? BootayarTheme.electricViolet.opacity(0.38) : Color(nsColor: .separatorColor).opacity(0.65)),
                        lineWidth: isExpanded || isHovered ? 1.2 : 1.0
                    )
            )
            .shadow(
                color: isHovered ? BootayarTheme.indigo.opacity(0.10) : .black.opacity(0.04),
                radius: isHovered ? 6 : 2,
                y: isHovered ? 2 : 1
            )
            .animation(.easeOut(duration: 0.16), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func bootayarCard(statusColor: Color = BootayarTheme.indigo, isExpanded: Bool = false) -> some View {
        modifier(BootayarCardModifier(statusColor: statusColor, isExpanded: isExpanded))
    }
}
