import SwiftUI

enum CFBottomSheetActionPlacement: Equatable, Sendable {
    case none
    case fixedFooter
    case scrollFooter
}

struct CFBottomSheetScaffold<Header: View, Content: View, BottomAction: View>: View {
    var contentBottomPadding: CGFloat = CFSpacing.xxl
    var actionPlacement: CFBottomSheetActionPlacement = .fixedFooter
    var initialScrollID: AnyHashable?
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content
    @ViewBuilder var bottomAction: () -> BottomAction

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(CFColor.divider)
                .frame(width: 48, height: 6)
                .padding(.top, CFSpacing.lg)
                .padding(.bottom, CFSpacing.xl)

            header()
                .padding(.horizontal, CFSpacing.xl)
                .padding(.bottom, CFSpacing.xl)

            if actionPlacement == .none {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        content()
                            .padding(.horizontal, CFSpacing.xl)
                            .padding(.bottom, contentBottomPadding)
                    }
                    .onAppear {
                        guard let initialScrollID else { return }
                        // Wait for the sheet's layout pass before scrolling to a content anchor.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            proxy.scrollTo(initialScrollID, anchor: .top)
                        }
                    }
                }
            } else if actionPlacement == .fixedFooter {
                ScrollView(showsIndicators: false) {
                    content()
                        .padding(.horizontal, CFSpacing.xl)
                        .padding(.bottom, contentBottomPadding)
                }

                fixedFooter
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        content()
                            .padding(.horizontal, CFSpacing.xl)
                            .padding(.bottom, CFSpacing.xxl)

                        bottomAction()
                            .padding(.horizontal, CFSpacing.xl)
                            .padding(.bottom, CFSpacing.lg)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(CFRadius.sheet)
        .presentationDragIndicator(.hidden)
        .presentationContentInteraction(.scrolls)
        .background(CFColor.backgroundPrimary)
    }

    private var fixedFooter: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    CFColor.backgroundPrimary.opacity(0),
                    CFColor.backgroundPrimary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            bottomAction()
                .padding(.horizontal, CFSpacing.xl)
                .padding(.top, CFSpacing.md)
                .padding(.bottom, CFSpacing.lg)
                .background(CFColor.backgroundPrimary)
        }
    }
}

#Preview("Bottom Sheet Scaffold") {
    CFBottomSheetScaffold {
        HStack {
            Text("Sheet")
                .font(CFFont.screenTitle)
            Spacer()
            Text("Confirm")
                .font(CFFont.cardTitle)
        }
    } content: {
        VStack(alignment: .leading, spacing: CFSpacing.xl) {
            Text("Sheet Content")
                .font(CFFont.screenTitle)

            ForEach(0..<8) { index in
                Text("Reusable row \(index + 1)")
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(CFColor.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous))
            }
        }
    } bottomAction: {
        CFPrimaryButton(title: "Save") {}
    }
}
