import SwiftUI
import Combine

// MARK: - Theme Definition
struct DiaryTheme {
    let name: String

    // Backgrounds
    let background: Color
    let backgroundSecondary: Color
    let cardBackground: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    // Accent
    let accent: Color
    let accentLight: Color

    // UI Elements
    let border: Color
    let divider: Color

    // Status
    let error: Color
    let success: Color
}

// MARK: - Predefined Themes
extension DiaryTheme {
    /// Warm cream theme matching the web app
    static let diary = DiaryTheme(
        name: "Diary",
        background: Color(hex: "FAF8F5"),
        backgroundSecondary: Color(hex: "F5F0E8"),
        cardBackground: .white,
        textPrimary: Color(hex: "1A1A1A"),
        textSecondary: Color(hex: "666666"),
        textTertiary: Color(hex: "A4A4A4"),
        accent: Color(hex: "B08D56"),
        accentLight: Color(hex: "D9C9AE"),
        border: Color(hex: "E8DFD0"),
        divider: Color(hex: "E3E3E3"),
        error: Color(hex: "DC2626"),
        success: Color(hex: "16A34A")
    )

    /// Deep navy dark theme
    static let navy = DiaryTheme(
        name: "Deep Navy",
        background: Color(hex: "0F172A"),
        backgroundSecondary: Color(hex: "1E293B"),
        cardBackground: Color(hex: "1E293B"),
        textPrimary: Color(hex: "F8FAFC"),
        textSecondary: Color(hex: "94A3B8"),
        textTertiary: Color(hex: "64748B"),
        accent: Color(hex: "60A5FA"),
        accentLight: Color(hex: "3B82F6").opacity(0.2),
        border: Color(hex: "334155"),
        divider: Color(hex: "334155"),
        error: Color(hex: "F87171"),
        success: Color(hex: "4ADE80")
    )

    /// Charcoal dark theme
    static let charcoal = DiaryTheme(
        name: "Charcoal",
        background: Color(hex: "18181B"),
        backgroundSecondary: Color(hex: "27272A"),
        cardBackground: Color(hex: "27272A"),
        textPrimary: Color(hex: "FAFAFA"),
        textSecondary: Color(hex: "A1A1AA"),
        textTertiary: Color(hex: "71717A"),
        accent: Color(hex: "A78BFA"),
        accentLight: Color(hex: "8B5CF6").opacity(0.2),
        border: Color(hex: "3F3F46"),
        divider: Color(hex: "3F3F46"),
        error: Color(hex: "F87171"),
        success: Color(hex: "4ADE80")
    )

    /// Earthy warm dark theme
    static let earthy = DiaryTheme(
        name: "Earthy",
        background: Color(hex: "1C1917"),
        backgroundSecondary: Color(hex: "292524"),
        cardBackground: Color(hex: "292524"),
        textPrimary: Color(hex: "FAFAF9"),
        textSecondary: Color(hex: "A8A29E"),
        textTertiary: Color(hex: "78716C"),
        accent: Color(hex: "D97706"),
        accentLight: Color(hex: "F59E0B").opacity(0.2),
        border: Color(hex: "44403C"),
        divider: Color(hex: "44403C"),
        error: Color(hex: "F87171"),
        success: Color(hex: "4ADE80")
    )

    static let all: [DiaryTheme] = [.diary, .navy, .charcoal, .earthy]
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: DiaryTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.name, forKey: "selectedTheme")
        }
    }

    private init() {
        let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Diary"
        self.currentTheme = DiaryTheme.all.first { $0.name == savedThemeName } ?? .diary
    }

    func setTheme(_ theme: DiaryTheme) {
        currentTheme = theme
    }
}

// MARK: - Color Hex Extension
extension Color {
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

// MARK: - Environment Key
struct ThemeKey: EnvironmentKey {
    static let defaultValue: DiaryTheme = .diary
}

extension EnvironmentValues {
    var theme: DiaryTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extension for Theme
extension View {
    func themed() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
}

// MARK: - Custom Fonts
enum DiaryFont {
    static let playfairRegular = "PlayfairDisplay-Regular"
    static let playfairBold = "PlayfairDisplay-Bold"
    static let playfairItalic = "PlayfairDisplay-Italic"
}

extension Font {
    /// Playfair Display - Regular
    static func playfair(size: CGFloat) -> Font {
        .custom(DiaryFont.playfairRegular, size: size)
    }

    /// Playfair Display - Bold
    static func playfairBold(size: CGFloat) -> Font {
        .custom(DiaryFont.playfairBold, size: size)
    }

    /// Playfair Display - Italic
    static func playfairItalic(size: CGFloat) -> Font {
        .custom(DiaryFont.playfairItalic, size: size)
    }
}

extension View {
    /// Apply Playfair Display font for logo/headings
    func playfairFont(size: CGFloat = 36) -> some View {
        self.font(.playfair(size: size))
    }
}
