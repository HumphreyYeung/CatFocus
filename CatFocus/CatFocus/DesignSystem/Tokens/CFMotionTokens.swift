import SwiftUI

enum CFMotionDuration {
    static let instantFeedback: Double = 0.12
    static let componentTransition: Double = 0.24
    static let layoutTransition: Double = 0.36
    static let celebration: Double = 0.52
    static let mascotTransitionCover: Double = 0.22
    static let mascotTransitionReveal: Double = 0.22
    static let interactionFeedback: Double = 0.16
    static let trainingControlsVisibility: Double = 0.22
}

enum CFMotionCurve {
    static let instantFeedback = Animation.easeOut(duration: CFMotionDuration.instantFeedback)
    static let componentTransition = Animation.easeOut(duration: CFMotionDuration.componentTransition)
    static let layoutTransition = Animation.easeOut(duration: CFMotionDuration.layoutTransition)
    static let celebration = Animation.spring(response: 0.42, dampingFraction: 0.86)

    static let mascotTransitionCover = Animation.easeOut(
        duration: CFMotionDuration.mascotTransitionCover
    )

    static let mascotTransitionReveal = Animation.easeOut(
        duration: CFMotionDuration.mascotTransitionReveal
    )

    static let interactionFeedback = Animation.easeOut(
        duration: CFMotionDuration.interactionFeedback
    )

    static let trainingControlsVisibility = Animation.easeOut(
        duration: CFMotionDuration.trainingControlsVisibility
    )
}

struct CFPressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed && !reduceMotion ? 0.88 : 1)
            .animation(
                reduceMotion ? .linear(duration: 0.01) : CFMotionCurve.instantFeedback,
                value: configuration.isPressed
            )
    }
}

struct CFAnimatedNumber: View {
    var value: String
    var font: Font = CFFont.heroNumber
    var color: Color = CFColor.textPrimary

    var body: some View {
        Text(value)
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .animation(CFMotionCurve.componentTransition, value: value)
    }
}

enum CFPageTransition {
    static var forward: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    static var quiet: AnyTransition {
        .opacity
    }
}

struct CFAnimatedVisibility: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var delay: Double = 0
    var offset: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : offset)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.98)
            .onAppear {
                guard !isVisible else { return }
                if reduceMotion || delay == 0 {
                    withAnimation(reduceMotion ? .linear(duration: 0.01) : CFMotionCurve.layoutTransition) {
                        isVisible = true
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(reduceMotion ? .linear(duration: 0.01) : CFMotionCurve.layoutTransition) {
                            isVisible = true
                        }
                    }
                }
            }
    }
}

extension View {
    func cfEntrance(delay: Double = 0, offset: CGFloat = 8) -> some View {
        modifier(CFAnimatedVisibility(delay: delay, offset: offset))
    }
}
