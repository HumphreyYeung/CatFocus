import SwiftUI

struct CFPrimaryButton: View {
    var title: String
    var icon: CFIcon?
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var variant: CFPrimaryButtonVariant = .standard
    var action: () -> Void

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
