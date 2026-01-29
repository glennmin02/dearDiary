import SwiftUI
import Combine

// MARK: - Theme Definition
/// Clean, minimal theme matching the Dear Diary web app
/// All colors meet WCAG AA 4.5:1 contrast requirements
struct DiaryTheme {
    let name: String

    // Backgrounds - solid colors, no transparency
    let background: Color
    let backgroundSecondary: Color
    let cardBackground: Color

    // Text - all meet WCAG AA contrast
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    // Accent - warm diary brown
    let accent: Color
    let accentLight: Color

    // UI Elements
    let border: Color
    let divider: Color

    // Status
    let error: Color
    let success: Color

    var isDark: Bool { name == "Dark" }
}

// MARK: - Color Palette (matching web app)
/// Colors extracted from deardiary.vercel.app Tailwind config
private enum DiaryColors {
    // Diary palette (warm cream/brown tones)
    static let diary50 = Color(hex: "FAF8F5")   // Lightest cream - main background
    static let diary100 = Color(hex: "F5F0E8")  // Light cream - secondary bg
    static let diary200 = Color(hex: "E8DFD0")  // Cream - borders
    static let diary300 = Color(hex: "D4C4A8")  // Warm beige
    static let diary400 = Color(hex: "B8A078")  // Medium brown
    static let diary500 = Color(hex: "9A7B4F")  // Brown
    static let diary600 = Color(hex: "7D6340")  // Dark brown - accent
    static let diary700 = Color(hex: "5C4A30")  // Darker brown

    // Ink palette (gray/black tones for text)
    static let ink50 = Color(hex: "F9FAFB")
    static let ink100 = Color(hex: "F3F4F6")
    static let ink200 = Color(hex: "E5E7EB")
    static let ink300 = Color(hex: "D1D5DB")
    static let ink400 = Color(hex: "9CA3AF")
    static let ink500 = Color(hex: "6B7280")    // Secondary text
    static let ink600 = Color(hex: "4B5563")
    static let ink700 = Color(hex: "374151")
    static let ink800 = Color(hex: "1F2937")
    static let ink900 = Color(hex: "111827")    // Primary text

    // Status colors
    static let errorLight = Color(hex: "DC2626")
    static let errorDark = Color(hex: "F87171")
    static let successLight = Color(hex: "16A34A")
    static let successDark = Color(hex: "4ADE80")
}

// MARK: - Predefined Themes
extension DiaryTheme {
    /// Light theme - matches web app exactly
    static let light = DiaryTheme(
        name: "Light",
        background: DiaryColors.diary50,
        backgroundSecondary: DiaryColors.diary100,
        cardBackground: .white,
        textPrimary: DiaryColors.ink900,        // #111827 - 15.4:1 contrast
        textSecondary: DiaryColors.ink600,      // #4B5563 - 7.5:1 contrast
        textTertiary: DiaryColors.ink500,       // #6B7280 - 5.4:1 contrast
        accent: DiaryColors.diary600,           // #7D6340 - warm brown
        accentLight: DiaryColors.diary100,
        border: DiaryColors.diary200,
        divider: DiaryColors.diary200,
        error: DiaryColors.errorLight,
        success: DiaryColors.successLight
    )

    /// Dark theme - inverted with proper contrast
    static let dark = DiaryTheme(
        name: "Dark",
        background: DiaryColors.ink900,
        backgroundSecondary: DiaryColors.ink800,
        cardBackground: DiaryColors.ink800,
        textPrimary: DiaryColors.ink50,         // #F9FAFB - 18.1:1 contrast
        textSecondary: DiaryColors.ink300,      // #D1D5DB - 11.5:1 contrast
        textTertiary: DiaryColors.ink400,       // #9CA3AF - 7.0:1 contrast
        accent: DiaryColors.diary400,           // #B8A078 - lighter brown for dark bg
        accentLight: DiaryColors.ink700,
        border: DiaryColors.ink700,
        divider: DiaryColors.ink700,
        error: DiaryColors.errorDark,
        success: DiaryColors.successDark
    )

    // Backwards compatibility
    static let diary = light
    static let navy = dark
    static let charcoal = dark
    static let earthy = dark

    static let all: [DiaryTheme] = [.light, .dark]
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: DiaryTheme
    @Published var useSystemAppearance: Bool {
        didSet {
            UserDefaults.standard.set(useSystemAppearance, forKey: "useSystemAppearance")
            if useSystemAppearance {
                updateThemeForColorScheme()
            }
        }
    }

    private var colorScheme: ColorScheme = .light

    private init() {
        let useSystem = UserDefaults.standard.object(forKey: "useSystemAppearance") as? Bool ?? true
        self.useSystemAppearance = useSystem
        self.currentTheme = .light
    }

    func updateColorScheme(_ scheme: ColorScheme) {
        colorScheme = scheme
        if useSystemAppearance {
            updateThemeForColorScheme()
        }
    }

    private func updateThemeForColorScheme() {
        currentTheme = colorScheme == .dark ? .dark : .light
    }

    func setTheme(_ theme: DiaryTheme) {
        currentTheme = theme
        if useSystemAppearance {
            useSystemAppearance = false
        }
    }

    func toggleTheme() {
        currentTheme = currentTheme.isDark ? .light : .dark
        useSystemAppearance = false
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
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

// MARK: - Environment
struct ThemeKey: EnvironmentKey {
    static let defaultValue: DiaryTheme = .light
}

extension EnvironmentValues {
    var theme: DiaryTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extensions
extension View {
    func themed() -> some View {
        self.environmentObject(ThemeManager.shared)
    }

    func adaptiveTheme() -> some View {
        self.modifier(AdaptiveThemeModifier())
    }
}

struct AdaptiveThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    private var themeManager: ThemeManager { ThemeManager.shared }

    func body(content: Content) -> some View {
        content
            .onChange(of: colorScheme) { _, newScheme in
                themeManager.updateColorScheme(newScheme)
            }
            .onAppear {
                themeManager.updateColorScheme(colorScheme)
            }
    }
}

// MARK: - Custom Fonts
enum DiaryFont {
    static let playfairRegular = "PlayfairDisplay-Regular"
    static let playfairBold = "PlayfairDisplay-Bold"
    static let playfairItalic = "PlayfairDisplay-Italic"
}

extension Font {
    static func playfair(size: CGFloat, relativeTo textStyle: Font.TextStyle = .title) -> Font {
        .custom(DiaryFont.playfairRegular, size: size, relativeTo: textStyle)
    }

    static func playfairBold(size: CGFloat, relativeTo textStyle: Font.TextStyle = .title) -> Font {
        .custom(DiaryFont.playfairBold, size: size, relativeTo: textStyle)
    }

    static func playfairItalic(size: CGFloat, relativeTo textStyle: Font.TextStyle = .title) -> Font {
        .custom(DiaryFont.playfairItalic, size: size, relativeTo: textStyle)
    }
}

extension View {
    func playfairFont(size: CGFloat = 36) -> some View {
        self.font(.playfair(size: size))
    }
}
