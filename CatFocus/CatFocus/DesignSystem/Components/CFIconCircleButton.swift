import SwiftUI

struct CFIconCircleButton: View {
    var icon: CFIcon
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            icon.image
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(CFColor.textPrimary)
                .frame(width: 36, height: 36)
                .background(CFColor.surfaceSoft)
                .clipShape(Circle())
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel(label)
    }
}

#Preview("Icon Circle Button") {
    HStack(spacing: CFSpacing.lg) {
        CFIconCircleButton(icon: .gear, label: "Settings") {}
        CFIconCircleButton(icon: .music, label: "White noise") {}
    }
    .padding()
}
