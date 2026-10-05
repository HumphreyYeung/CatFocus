import SwiftUI

struct CFTimeOptionRow: View {
    var title: String
    @Binding var selection: Int
    var choices: [Int]

    var body: some View {
        HStack(spacing: CFSpacing.sm) {
            Text(CFLocalization.text(title).uppercased())
                .font(CFFont.labelCaps)
                .tracking(1.2)
                .foregroundStyle(CFColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(width: 84, alignment: .leading)

            GeometryReader { proxy in
                let selectedX = xPosition(forChoice: selection, in: proxy.size.width)
                let trackInset = selectedNodeDiameter / 2
                let trackWidth = max(proxy.size.width - selectedNodeDiameter, 0)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CFColor.surfaceSoft)
                        .frame(width: trackWidth, height: 5)
                        .offset(x: trackInset)

                    Capsule()
                        .fill(CFColor.surfaceSelected)
                        .frame(width: max(selectedX - trackInset, 0), height: 5)
                        .offset(x: trackInset)

                    ForEach(Array(choices.enumerated()), id: \.element) { index, choice in
                        Circle()
                            .fill(choice == selection ? CFColor.surfaceSelected : CFColor.divider)
                            .frame(
                                width: choice == selection ? selectedNodeDiameter : 6,
                                height: choice == selection ? selectedNodeDiameter : 6
                            )
                            .position(
                                x: xPosition(forIndex: index, in: proxy.size.width),
                                y: proxy.size.height / 2
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(coordinateSpace: .local) { location in
                    updateSelection(at: location.x, in: proxy.size.width)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 2, coordinateSpace: .local)
                        .onChanged { value in
                            guard abs(value.translation.width) >= abs(value.translation.height) else { return }
                            updateSelection(at: value.location.x, in: proxy.size.width)
                        }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(CFLocalization.text(title))
                .accessibilityValue("\(selection) minutes")
                .accessibilityAdjustableAction(adjustSelection)
            }
            .frame(height: 44)

            Text("\(selection) min")
                .font(CFFont.cardTitle)
                .foregroundStyle(CFColor.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 78, alignment: .trailing)
        }
        .frame(minHeight: 48)
    }

    private let selectedNodeDiameter: CGFloat = 18

    private func xPosition(forChoice choice: Int, in totalWidth: CGFloat) -> CGFloat {
        xPosition(forIndex: choices.firstIndex(of: choice) ?? 0, in: totalWidth)
    }

    private func xPosition(forIndex index: Int, in totalWidth: CGFloat) -> CGFloat {
        let trackInset = selectedNodeDiameter / 2
        guard choices.count > 1 else { return totalWidth / 2 }
        let trackWidth = max(totalWidth - selectedNodeDiameter, 0)
        return trackInset + trackWidth / CGFloat(choices.count - 1) * CGFloat(index)
    }

    private func updateSelection(at x: CGFloat, in totalWidth: CGFloat) {
        guard !choices.isEmpty else { return }
        guard choices.count > 1 else {
            selection = choices[0]
            return
        }

        let trackInset = selectedNodeDiameter / 2
        let trackWidth = max(totalWidth - selectedNodeDiameter, 1)
        let progress = min(max((x - trackInset) / trackWidth, 0), 1)
        let index = Int((progress * CGFloat(choices.count - 1)).rounded())
        let newSelection = choices[index]
        if selection != newSelection {
            selection = newSelection
        }
    }

    private func adjustSelection(_ direction: AccessibilityAdjustmentDirection) {
        guard let index = choices.firstIndex(of: selection) else {
            selection = choices.first ?? selection
            return
        }

        switch direction {
        case .increment where index < choices.count - 1:
            selection = choices[index + 1]
        case .decrement where index > 0:
            selection = choices[index - 1]
        default:
            break
        }
    }
}
