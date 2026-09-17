import SwiftUI

struct CFPrimaryButton: View {
    var title: String
    var icon: CFIcon?
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var showsSweep: Bool = false
    var variant: CFPrimaryButtonVariant = .standard
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: CFSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(CFColor.textInverse)
                } else if let icon {
                    icon.image
                        .font(.system(size: 15, weight: .black))
                }

                Text(title.uppercased())
                    .font(CFFont.button)
                    .tracking(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(CFColor.textInverse)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 20)
            .background(CFCloudLayer.graphite)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                if showsSweep && !isLoading && !isDisabled && !reduceMotion {
            KeyframeAnimator(initialValue: CGFloat(-1.35), repeating: true) { progress in
                        GeometryReader { proxy in
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.24),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 72, height: proxy.size.height * 1.8)
                            .rotationEffect(.degrees(18))
                            .offset(x: progress * (proxy.size.width + 72))
                        }
                    }
                    keyframes: { _ in
                        LinearKeyframe(-1.35, duration: 1.65)
                        LinearKeyframe(1.35, duration: 0.68)
                        LinearKeyframe(1.35, duration: 2.15)
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .opacity(isDisabled ? 0.44 : 1)
            .cfShadow(isDisabled ? CFShadowStyle(color: .clear, radius: 0, x: 0, y: 0) : CFShadow.cta)
        }
        .buttonStyle(CFPressableStyle())
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
    }
}

#Preview("Primary Button") {
    VStack(spacing: CFSpacing.xl) {
        CFPrimaryButton(title: "Start") {}
        CFPrimaryButton(title: "Back to Home", icon: .play) {}
        CFPrimaryButton(title: "Continue", isLoading: true) {}
        CFPrimaryButton(title: "Continue", isDisabled: true) {}
    }
    .padding()
}
