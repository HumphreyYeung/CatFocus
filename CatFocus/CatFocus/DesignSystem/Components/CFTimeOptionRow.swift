import SwiftUI

struct CFTimeOptionRow: View {
    var title: String
    @Binding var selection: Int
    var choices: [Int]

    var body: some View {
        VStack(spacing: CFSpacing.md) {
            HStack {
                Text(title.uppercased())
                    .font(CFFont.labelCaps)
                    .tracking(2.2)
                    .foregroundStyle(CFColor.textSecondary)

                Spacer()

                Text("\(selection) min")
                    .font(CFFont.cardTitle)
                    .foregroundStyle(CFColor.textPrimary)
            }

            GeometryReader { proxy in
                let progress = progressWidth(in: proxy.size.width)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CFColor.surfaceSoft)
                        .frame(height: 5)

                    Capsule()
                        .fill(CFColor.surfaceSelected)
                        .frame(width: progress, height: 5)

                    HStack(spacing: 0) {
                        ForEach(choices, id: \.self) { choice in
                            Button {
                                selection = choice
                            } label: {
                                ZStack {
                                    Color.clear

                                    Circle()
                                        .fill(choice == selection ? CFColor.surfaceSelected : CFColor.divider)
                                        .frame(
                                            width: choice == selection ? 22 : 6,
                                            height: choice == selection ? 22 : 6
                                        )
                                }
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(title) \(choice) minutes")
                            .accessibilityAddTraits(choice == selection ? .isSelected : [])
                        }
                    }
                }
            }
            .frame(height: 44)
        }
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard choices.count > 1, let index = choices.firstIndex(of: selection) else { return 0 }
        return totalWidth / CGFloat(choices.count - 1) * CGFloat(index)
    }
}
