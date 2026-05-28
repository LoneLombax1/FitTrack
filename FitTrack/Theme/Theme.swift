// FitTrack/Theme/Theme.swift
import SwiftUI

enum Theme {

    // MARK: - Colors
    enum Colors {
        static let bg          = Color(hex: "0A0A0A")
        static let surface     = Color(hex: "0D1117")
        static let surfaceDeep = Color(hex: "080B10")

        static let borderSubtle = Color.white.opacity(0.067)
        static let borderCyan   = Color(hex: "00F5FF").opacity(0.13)
        static let borderPurple = Color(hex: "B000FF").opacity(0.20)

        static let cyan       = Color(hex: "00F5FF")
        static let cyanDim    = Color(hex: "00F5FF").opacity(0.4)
        static let purple     = Color(hex: "B000FF")
        static let purpleDim  = Color(hex: "B000FF").opacity(0.27)

        static let textPrimary   = Color.white
        static let textSecondary = Color.white.opacity(0.6)
        static let textMuted     = Color.white.opacity(0.27)

        static func recovery(_ score: Int) -> Color {
            switch score {
            case 75...: return Color(hex: "00FF88")
            case 50..<75: return Color(hex: "FFB800")
            default: return Color(hex: "FF3B5C")
            }
        }
    }

    // MARK: - Typography
    enum Fonts {
        static func orbitron(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            Font.custom("Orbitron-Bold", size: size)
        }

        static func rajdhani(_ size: CGFloat) -> Font {
            Font.custom("Rajdhani-SemiBold", size: size)
        }

        static func mono(_ size: CGFloat, bold: Bool = false) -> Font {
            Font.custom(bold ? "JetBrainsMono-Bold" : "JetBrainsMono-Regular", size: size)
        }
    }

    // MARK: - Animation
    enum Anim {
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let bounce = Animation.spring(response: 0.35, dampingFraction: 0.6)
        static let fast   = Animation.spring(response: 0.25, dampingFraction: 0.8)
    }

    // MARK: - Layout
    enum Layout {
        static let cardRadius: CGFloat = 16
        static let innerRadius: CGFloat = 10
        static let buttonRadius: CGFloat = 10
        static let screenPadding: CGFloat = 16
        static let cardGap: CGFloat = 12
    }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Glow shadow modifier
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func neonGlow(_ color: Color = Theme.Colors.cyan, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Appear animation modifier
struct AppearAnimationModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(Theme.Anim.spring.delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearAnimationModifier(delay: delay))
    }
}
