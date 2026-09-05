import SwiftUI

enum CFStatusTone: Equatable, Sendable {
    case neutral
    case health
    case success
    case danger
    case reward

    var foreground: Color {
        switch self {
        case .neutral:
            CFColor.textPrimary
        case .health:
            CFColor.textPrimary
        case .success:
            CFColor.accentSuccess
        case .danger:
            CFColor.accentDanger
        case .reward:
            CFColor.textPrimary
        }
    }

    var background: Color {
        switch self {
        case .neutral, .health, .reward:
            CFColor.surfaceSoft
        case .success:
            CFColor.accentSuccess.opacity(0.12)
        case .danger:
            CFColor.accentDanger.opacity(0.12)
        }
    }

    var iconColor: Color {
        switch self {
        case .health:
            CFColor.accentDanger
        case .success:
            CFColor.accentSuccess
        case .danger:
            CFColor.accentDanger
        case .neutral, .reward:
            CFColor.textPrimary
        }
    }
}

struct CFStatusPill: View {
    var icon: CFIcon
    var text: String
    var tone: CFStatusTone = .neutral

    var body: some View {
        HStack(spacing: CFSpacing.xs) {
            icon.image
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(tone.iconColor)

            Text(text.uppercased())
                .font(CFFont.labelCaps)
                .tracking(0.6)
                .foregroundStyle(tone.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .contentTransition(.numericText())
                .animation(CFMotionCurve.componentTransition, value: text)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 28)
        .background(tone.background)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(CFColor.borderSubtle, lineWidth: 1)
        }
    }
}

struct CFFitnessStatusPill: View {
    var score: FitnessScore

    var body: some View {
        HStack(spacing: CFSpacing.xs) {
            CFIcon.heart.image
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(CFColor.accentDanger)

            CFAnimatedNumber(
                value: "\(score.value)%",
                font: .system(size: 12, weight: .black, design: .rounded).monospacedDigit()
            )

            Text(score.healthStatus.displayLabel.uppercased())
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(CFColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 28)
        .background(CFColor.surfaceSoft)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(CFColor.borderSubtle, lineWidth: 1)
        }
        .accessibilityLabel("Fitness \(score.value) percent, \(score.healthStatus.displayLabel)")
    }
}

#Preview("Status Pills") {
    VStack(spacing: CFSpacing.md) {
        CFStatusPill(icon: .heart, text: "Needs Training", tone: .health)
        CFFitnessStatusPill(score: FitnessScore(42))
        CFStatusPill(icon: .focus, text: "Focus", tone: .neutral)
        CFStatusPill(icon: .spark, text: "Fit Points +100", tone: .success)
        CFStatusPill(icon: .spark, text: "Fit Points -50", tone: .danger)
    }
    .padding()
}
