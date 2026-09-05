import SwiftUI
import UIKit

struct ShareCardOverlay: View {
    var cat: CatProfile = .default
    var catAsset: CFCatAsset = .staticImage(name: "luna-success")
    var focusMinutes: Int = 45
    var fitPoints: Int = 120
    var health: FitnessScore = FitnessScore(98)
    var onClose: () -> Void = {}
    @State private var isSavingCard = false
    @State private var isCardSaved = false
    @State private var cardError: String?
    @State private var shareImage: UIImage?
    @State private var isShareSheetPresented = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CFColor.backgroundDimmed
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: CFSpacing.lg) {
                        shareCard(
                            width: min(proxy.size.width - 48, 354),
                            height: min(650, max(548, proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom - 172))
                        )

                        Text("SHARE TO WORLD")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(6.0)
                            .foregroundStyle(CFColor.textInverse)
                            .padding(.top, CFSpacing.lg)

                        shareActionsTray
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, max(24, proxy.safeAreaInsets.top + 16))
                    .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 16))
                }
            }
        }
        .alert("Card Saved", isPresented: $isCardSaved) {
            Button("OK") {}
        } message: {
            Text("Your focus card is now in Photos.")
        }
        .alert("Save Card", isPresented: Binding(
            get: { cardError != nil },
            set: { if !$0 { cardError = nil } }
        )) {
            Button("OK") { cardError = nil }
        } message: {
            Text(cardError ?? "")
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let shareImage {
                CFImageShareSheet(image: shareImage)
            }
        }
    }

    private func shareCard(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                Button(action: onClose) {
                    CFIcon.xmark.image
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(CFColor.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(CFColor.surfaceSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close share card")
            }
            .padding(.top, CFSpacing.md)
            .padding(.trailing, CFSpacing.md)

            CFCatHero(asset: catAsset, size: .medium)
                .frame(width: 246, height: 196)
                .padding(.top, CFSpacing.md)

            Spacer(minLength: CFSpacing.xl)

            Text("\"THANK YOU FOR STAYING FOCUSED. I\nFEEL MUCH STRONGER NOW!\"")
                .font(.system(size: 14, weight: .black, design: .rounded).italic())
                .foregroundStyle(CFColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .minimumScaleFactor(0.85)
                .accessibilityLabel("THANK YOU FOR STAYING FOCUSED. I FEEL MUCH STRONGER NOW!")

            Spacer(minLength: CFSpacing.xl)

            HStack(spacing: 0) {
                CFShareMetric(label: "Focus Time", value: "\(focusMinutes)", suffix: "min")
                CFShareMetric(
                    label: "Fit Points",
                    value: fitPoints > 0 ? "+\(fitPoints)" : "\(fitPoints)"
                )
                CFShareMetric(label: "Health", value: "\(health.value)", suffix: "%")
            }
            .padding(.horizontal, 28)

            Rectangle()
                .fill(CFColor.divider)
                .frame(height: 1)
                .padding(.horizontal, 32)
                .padding(.top, CFSpacing.xl)

            HStack {
                HStack(spacing: CFSpacing.sm) {
                    CFCatAppIconMark()
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PAW-MODORO")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(CFColor.textPrimary)

                        Text("ONLY ON IOS")
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(CFColor.textSecondary)
                    }
                }

                Spacer()

                CFAppStoreBadge()
            }
            .padding(.horizontal, 32)
            .padding(.top, CFSpacing.lg)
            .padding(.bottom, 26)
        }
        .frame(width: width, height: height)
        .background(CFColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 10)
    }

    private var shareActionsTray: some View {
            HStack(spacing: CFSpacing.lg) {
            CFShareActionButton(
                icon: .download,
                title: isSavingCard ? "Saving" : "Save",
                accessibilityLabel: "Save share card",
                isLoading: isSavingCard,
                action: saveCard
            )
            CFShareActionButton(icon: .camera, title: "Instagram", accessibilityLabel: "Instagram share card", action: shareCard)
            CFShareActionButton(icon: .music, title: "TikTok", accessibilityLabel: "TikTok share card", action: shareCard)
            CFShareActionButton(icon: .message, title: "Message", accessibilityLabel: "Message share card", action: shareCard)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, CFSpacing.xxl)
        .padding(.vertical, CFSpacing.lg)
        .background(CFColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 8)
        .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
    }

    private func renderShareCard() -> UIImage? {
        let renderer = ImageRenderer(content: shareCard(width: 354, height: 650))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func saveCard() {
        guard !isSavingCard, let image = renderShareCard() else { return }
        isSavingCard = true

        Task {
            do {
                try await CFShareVideoComposer.saveToPhotos(image: image)
                await MainActor.run {
                    isSavingCard = false
                    isCardSaved = true
                }
            } catch {
                await MainActor.run {
                    isSavingCard = false
                    cardError = error.localizedDescription
                }
            }
        }
    }

    private func shareCard() {
        guard let image = renderShareCard() else { return }
        shareImage = image
        isShareSheetPresented = true
    }
}

private struct CFShareMetric: View {
    var label: String
    var value: String
    var suffix: String = ""

    var body: some View {
        VStack(spacing: CFSpacing.sm) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(CFColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(CFColor.textPrimary)

                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(CFColor.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CFShareActionButton: View {
    var icon: CFIcon
    var title: String
    var accessibilityLabel: String
    var isLoading = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: CFSpacing.sm) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(CFColor.textPrimary)
                    } else {
                        icon.image
                            .font(.system(size: 17, weight: .black))
                    }
                }
                    .foregroundStyle(CFColor.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(CFColor.surfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(CFColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct CFImageShareSheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private struct CFAppStoreBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            CFIcon.apple.image
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(CFColor.textInverse)

            VStack(alignment: .leading, spacing: 0) {
                Text("DOWNLOAD ON THE")
                    .font(.system(size: 5.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(CFColor.textInverse)

                Text("App Store")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(CFColor.textInverse)
            }
        }
        .padding(.horizontal, 11)
        .frame(height: 36)
        .background(CFColor.surfaceSelected)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct CFCatAppIconMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(CFColor.surfaceSelected)

            CFCatFaceMark()
                .frame(width: 23, height: 19)
        }
        .accessibilityHidden(true)
    }
}

private struct CFCatFaceMark: View {
    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 32, proxy.size.height / 26)

            ZStack {
                Circle()
                    .fill(CFColor.surfacePrimary)
                    .frame(width: 22, height: 20)

                HStack(spacing: 12) {
                    CFShareTriangle()
                        .fill(CFColor.surfacePrimary)
                        .frame(width: 8, height: 10)
                        .rotationEffect(.degrees(-16))

                    CFShareTriangle()
                        .fill(CFColor.surfacePrimary)
                        .frame(width: 8, height: 10)
                        .rotationEffect(.degrees(16))
                }
                .offset(y: -9)

                HStack(spacing: 5) {
                    Circle()
                        .fill(CFColor.surfaceSelected)
                        .frame(width: 3, height: 3)
                    Circle()
                        .fill(CFColor.surfaceSelected)
                        .frame(width: 3, height: 3)
                }
                .offset(y: -1)
            }
            .frame(width: 32, height: 26)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

private struct CFShareTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview("Share Card") {
    ShareCardOverlay()
}
