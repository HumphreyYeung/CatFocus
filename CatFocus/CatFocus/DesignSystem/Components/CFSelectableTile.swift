import SwiftUI

enum CFTileState: Equatable, Sendable {
    case selected
    case normal
    case add
    case locked
    case disabled
}

enum CFTileSize: Equatable, Sendable {
    case small
    case medium
    case sound
    case large

    var height: CGFloat {
        switch self {
        case .small:
            52
        case .medium:
            67
        case .sound:
            94
        case .large:
            168
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small:
            16
        case .medium:
            20
        case .sound:
            24
        case .large:
            48
        }
    }
}

struct CFSelectableTile: View {
    var icon: CFIcon
    var title: String
    var state: CFTileState
    var size: CFTileSize = .medium
    var action: () -> Void
    var showsShadow: Bool = true

    private var foreground: Color { CFColor.textPrimary }

    private var background: Color {
        switch state {
        case .selected:
            CFColor.surfacePrimary
        case .add:
            CFColor.surfacePrimary
        case .locked, .disabled:
            CFColor.surfaceSoft.opacity(0.72)
        case .normal:
            CFColor.surfacePrimary
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: CFSpacing.sm) {
                icon.image
                    .font(.system(size: size.iconSize, weight: .black))

                Text(title.uppercased())
                    .font(.system(size: 10.5, weight: state == .selected ? .bold : .semibold, design: .rounded))
                    .tracking(0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: size.height)
            .padding(.horizontal, CFSpacing.sm)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .stroke(state == .selected ? CFCloudLayer.graphite : CFColor.borderSubtle, lineWidth: state == .selected ? 1.8 : 0.8)
            }
            .cfShadow(showsShadow ? (state == .selected ? CFCloudLayer.selectionStrongShadow : CFCloudLayer.cardShadow) : CFShadowStyle(color: .clear, radius: 0, x: 0, y: 0))
            .opacity(state == .locked || state == .disabled ? 0.52 : 1)
            .animation(CFMotionCurve.componentTransition, value: state)
        }
        .buttonStyle(CFPressableStyle())
        .disabled(state == .locked || state == .disabled)
        .accessibilityLabel(title)
    }
}

#Preview("Selectable Tiles") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: CFSpacing.md), count: 3), spacing: CFSpacing.md) {
        CFSelectableTile(icon: .plus, title: "Add", state: .add) {}
        CFSelectableTile(icon: .focus, title: "Focus", state: .selected) {}
        CFSelectableTile(icon: .stats, title: "Study", state: .normal) {}
        CFSelectableTile(icon: .myCat, title: "Locked", state: .locked) {}
    }
    .padding()
}
