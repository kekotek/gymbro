import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Palette and type ramp taken from the reference screens in `design/screens/`.
enum Theme {
    static let background = Color(hex: 0x0F1114)
    static let surface = Color(hex: 0x1B1E23)
    static let surfaceRaised = Color(hex: 0x2A2E35)
    static let line = Color(hex: 0x272A30)
    static let textPrimary = Color(hex: 0xF1F0EC)
    static let textSecondary = Color(hex: 0x9A9DA3)
    /// Individual plan, primary actions, selected day.
    static let lime = Color(hex: 0xD4F542)
    /// Shared plan.
    static let cyan = Color(hex: 0x5CD8E8)
    /// Alerts, current time, destructive actions.
    static let coral = Color(hex: 0xF07A5C)
    static let onLime = Color(hex: 0x131608)
    static let onCyan = Color(hex: 0x0A2226)

    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy).width(.condensed)
    }

    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold).width(.condensed)
    }

    static func body(_ size: CGFloat = 17, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}
