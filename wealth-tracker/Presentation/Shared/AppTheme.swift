import SwiftUI

// MARK: - Color Palette

extension Color {
    static let appBackground = Color(hex: "F5F4F4")
    static let appSurface    = Color(hex: "E7E4E5")
    static let appPrimary    = Color(hex: "282526")
    static let appMuted      = Color(hex: "1B1818")
    static let appAccent     = Color(hex: "282526")
    /// Sage green — positive financial values
    static let appPositive   = Color(hex: "3D7A52")
    /// Warm red — negative financial values
    static let appNegative   = Color(hex: "A04040")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(
            .sRGB,
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >>  8) & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}

// MARK: - Shared View Modifiers

extension View {
    /// Standard themed row: parchment background + linen separator.
    func themedRow() -> some View {
        self
            .listRowBackground(Color.appSurface)
            .listRowSeparatorTint(Color.appBackground)
    }

    /// Removes default List / Form chrome and sets the linen background.
    func themedBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
    }
}

// MARK: - Section Header Style

struct ThemedSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.appMuted)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - Unified Account-Type Icon

struct AccountTypeIcon: View {
    let systemName: String
    var size: CGFloat = 38
    var cornerRadius: CGFloat = 10

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Color(hex: "433D3D"),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}
