import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary Background Colors
    static let dartsBackground = Color(hex: "0D0D0D")
    static let dartsCardBackground = Color(hex: "1A1A1A")
    static let dartsCardBorder = Color.white.opacity(0.1)
    
    // Accent Colors - Traditional Darts
    static let dartsRed = Color(hex: "E53935")
    static let dartsGreen = Color(hex: "2E7D32")
    
    // Text Colors
    static let dartsTextPrimary = Color.white
    static let dartsTextSecondary = Color.white.opacity(0.7)
    static let dartsTextTertiary = Color.white.opacity(0.5)
    
    // AI Accent
    static let dartsAI = Color(hex: "4FC3F7") // Light blue for AI sparkle
    
    // Status Colors
    static let dartsSuccess = Color(hex: "4CAF50")
    static let dartsWarning = Color(hex: "FFC107")
    static let dartsError = Color(hex: "E53935")
    
    // Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    static let dartsTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let dartsHeadline = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let dartsSubheadline = Font.system(size: 17, weight: .medium, design: .rounded)
    static let dartsBody = Font.system(size: 15, weight: .regular, design: .default)
    static let dartsCaption = Font.system(size: 13, weight: .regular, design: .default)
    static let dartsMetric = Font.system(size: 34, weight: .bold, design: .rounded)
}

// MARK: - Glassmorphism Card Modifier
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    var borderOpacity: Double = 0.15
    var backgroundOpacity: Double = 0.8
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.dartsCardBackground.opacity(backgroundOpacity))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.dartsCardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16, borderOpacity: Double = 0.15) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
}

// MARK: - Glow Effect Modifier
struct GlowEffect: ViewModifier {
    var color: Color
    var radius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 4)
            .shadow(color: color.opacity(0.2), radius: radius / 2, x: 0, y: 2)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 20) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - AI Sparkle Icon
struct AISparkle: View {
    var size: CGFloat = 16
    var color: Color = .dartsAI
    
    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Primary Button Style
struct DartsPrimaryButtonStyle: ButtonStyle {
    var color: Color = .dartsRed
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dartsSubheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
            )
            .glow(color: color, radius: configuration.isPressed ? 10 : 15)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DartsPrimaryButtonStyle {
    static var dartsPrimary: DartsPrimaryButtonStyle { DartsPrimaryButtonStyle() }
    static func dartsPrimary(color: Color) -> DartsPrimaryButtonStyle {
        DartsPrimaryButtonStyle(color: color)
    }
}

// MARK: - Secondary Button Style
struct DartsSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dartsSubheadline)
            .foregroundColor(.dartsTextPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dartsCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.dartsCardBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DartsSecondaryButtonStyle {
    static var dartsSecondary: DartsSecondaryButtonStyle { DartsSecondaryButtonStyle() }
}
