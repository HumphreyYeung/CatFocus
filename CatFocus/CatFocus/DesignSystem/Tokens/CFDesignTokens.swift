import SwiftUI

enum CFColor {
    static let backgroundPrimary = Color.white
    static let backgroundDimmed = Color.black.opacity(0.58)
    static let surfacePrimary = Color.white
    static let surfaceSoft = Color(red: 0.965, green: 0.965, blue: 0.975)
    static let surfaceWhisper = Color(red: 0.988, green: 0.988, blue: 0.992)
    static let surfaceSelection = Color(red: 0.905, green: 0.905, blue: 0.925)
    static let surfaceSelected = Color(red: 0.17, green: 0.17, blue: 0.19)
    static let surfaceElevated = Color.white

    static let textPrimary = Color(red: 0.17, green: 0.17, blue: 0.19)
    static let textSecondary = Color(red: 0.38, green: 0.38, blue: 0.43)
    static let textTertiary = Color(red: 0.62, green: 0.62, blue: 0.68)
    static let textInverse = Color.white

    static let borderPrimary = Color(red: 0.17, green: 0.17, blue: 0.19)
    static let borderSubtle = Color(red: 0.89, green: 0.89, blue: 0.92)
    static let borderSelected = Color(red: 0.72, green: 0.72, blue: 0.77)
    static let divider = Color(red: 0.90, green: 0.90, blue: 0.92)

    static let accentHealth = Color(red: 0.12, green: 0.62, blue: 0.30)
    static let accentSuccess = Color(red: 0.08, green: 0.55, blue: 0.24)
    static let accentDanger = Color(red: 1.00, green: 0.22, blue: 0.20)
    static let accentTrial = Color(red: 1.00, green: 0.34, blue: 0.18)
    static let accentReward = Color(red: 0.17, green: 0.17, blue: 0.19)
}

enum CFCloudLayer {
    static let graphite = Color(red: 0.17, green: 0.17, blue: 0.19)
    static let hairline = Color(red: 0.90, green: 0.90, blue: 0.92)
    static let cardShadow = CFShadowStyle(
        color: Color.black.opacity(0.045),
        radius: 4,
        x: 0,
        y: 2
    )
    static let selectedShadow = CFShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 7,
        x: 0,
        y: 3
    )
    static let selectionStrongShadow = CFShadowStyle(
        color: Color.black.opacity(0.16),
        radius: 10,
        x: 0,
        y: 4
    )
}

enum CFPrimaryButtonVariant {
    case standard
    case cloud
}

enum CFFont {
    static let screenTitle = Font.system(size: 26, weight: .black, design: .rounded)
    static let heroNumber = Font.system(size: 48, weight: .heavy, design: .rounded).monospacedDigit()
    static let sectionTitle = Font.system(size: 14, weight: .black, design: .rounded)
    static let cardTitle = Font.system(size: 16, weight: .bold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let button = Font.system(size: 15, weight: .bold, design: .rounded)
    static let labelCaps = Font.system(size: 10.5, weight: .bold, design: .rounded)
    static let dialogue = Font.system(size: 15, weight: .medium, design: .rounded)
    private static let handwrittenFamily = "ChalkboardSE-Regular"

    static var pactHandwritten: Font {
        Font.custom(handwrittenFamily, size: 17.5, relativeTo: .body)
    }

    static var pactHandwrittenSmall: Font {
        Font.custom(handwrittenFamily, size: 14.5, relativeTo: .subheadline)
    }
}

struct CFSectionTitle: View {
    var title: String

    var body: some View {
        Text(title)
            .font(CFFont.cardTitle)
            .foregroundStyle(CFColor.textPrimary)
    }
}

enum CFSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let section: CGFloat = 40
    static let screenHorizontal: CGFloat = 24
    static let bottomActionInset: CGFloat = 32
}

enum CFTabScreenLayout {
    static let horizontalPadding: CGFloat = CFSpacing.xl
    static let headerTopPadding: CGFloat = CFSpacing.lg
    static let headerBottomPadding: CGFloat = CFSpacing.lg
    static let scrollBottomPadding: CGFloat = 96
}

enum CFMascotLayout {
    static let topSpacing: CGFloat = 72
    static let focusMediaTopPadding: CGFloat = 48
    static let homePrimaryActionBottomPadding: CGFloat = 136
    static let homeControlsLift: CGFloat = CFSpacing.lg
}

enum CFButtonLayout {
    static let primaryHorizontalInset: CGFloat = 72
}

enum CFRadius {
    static let button: CGFloat = 14
    static let tile: CGFloat = 20
    static let card: CGFloat = 20
    static let largeCard: CGFloat = 24
    static let sheet: CGFloat = 36
    static let pill: CGFloat = 999
}

struct CFShadowStyle {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
}

enum CFShadow {
    static let cta = CFShadowStyle(
        color: Color.black.opacity(0.18),
        radius: 14,
        x: 0,
        y: 8
    )
    static let floating = CFShadowStyle(
        color: Color.black.opacity(0.18),
        radius: 14,
        x: 0,
        y: 8
    )
    static let cardSoft = CFShadowStyle(
        color: Color.black.opacity(0.07),
        radius: 8,
        x: 0,
        y: 4
    )
}

extension View {
    func cfShadow(_ style: CFShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
