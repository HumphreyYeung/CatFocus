import SwiftUI
import UIKit

struct ShareCardOverlay: View {
    var catAsset: CFCatAsset = .staticImage(name: "luna-success")
    var focusMinutes: Int = 45
    var averageFocusMinutes: Int = 45
    var focusDays: Int = 1
    var sessionCount: Int = 1
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

                VStack(spacing: CFSpacing.lg) {
                        ZStack(alignment: .topTrailing) {
                            shareCard(
                                width: min(proxy.size.width - 48, 354),
                                // Leave room for the action tray and the device's
                                // home-indicator area in the on-screen preview.
                                // Exported cards keep their independent 650pt size.
                                height: min(620, max(520, proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom - 208)),
                                showsShadow: true
                            )

                            Button(action: onClose) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.black.opacity(0.46))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .frame(width: 44, height: 44)
                            // Align the button's trailing edge with the card while
                            // keeping it clearly separated above the card surface.
                            .offset(x: 0, y: -52)
                            .accessibilityLabel("Close share card")
                        }
                        .padding(.top, 12)

                        Text("SHARE TO WORLD")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(6.0)
                            .foregroundStyle(CFColor.textInverse)
                            .padding(.top, CFSpacing.lg)

                        shareActionsTray
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, max(24, proxy.safeAreaInsets.top + 16))
                .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 16))
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

    private func shareCard(width: CGFloat, height: CGFloat, showsShadow: Bool = true) -> some View {
        VStack(spacing: 0) {
            CFCatHero(asset: catAsset, size: .medium)
                .frame(width: 246, height: 196)
                .padding(.top, CFSpacing.md)

            Spacer(minLength: CFSpacing.xl)

            Text("\"THANK YOU FOR STAYING FOCUSED. I FEEL MUCH STRONGER NOW!\"")
                .font(.system(size: 14, weight: .black, design: .rounded).italic())
                .foregroundStyle(CFColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .accessibilityLabel("THANK YOU FOR STAYING FOCUSED. I FEEL MUCH STRONGER NOW!")

            Spacer(minLength: CFSpacing.xl)

            VStack(spacing: CFSpacing.lg) {
                HStack(spacing: 0) {
                    CFShareMetric(label: "Focus Time", value: formattedDuration(focusMinutes))
                    CFShareMetric(label: "Avg", value: formattedDuration(averageFocusMinutes))
                }

                HStack(spacing: 0) {
                    CFShareMetric(label: "Focus Days", value: "\(focusDays)")
                    CFShareMetric(label: "Sessions", value: "\(sessionCount)")
                }
            }
            .padding(.horizontal, 28)

            Rectangle()
                .fill(CFColor.divider)
                .frame(height: 1)
                .padding(.horizontal, 32)
                .padding(.top, CFSpacing.xl)

            HStack {
                HStack(spacing: CFSpacing.sm) {
                    Image("ShareCardLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CATFOCUS")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(CFColor.textPrimary)
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
        .shadow(
            color: showsShadow ? Color.black.opacity(0.12) : .clear,
            radius: showsShadow ? 16 : 0,
            x: 0,
            y: showsShadow ? 10 : 0
        )
    }

    private var shareActionsTray: some View {
        HStack(spacing: CFSpacing.xxl) {
            CFShareActionButton(
                icon: .download,
                title: isSavingCard ? "Saving" : "Save",
                accessibilityLabel: "Save share card",
                isLoading: isSavingCard,
                action: saveCard
            )
            CFShareActionButton(icon: .share, title: "Share", accessibilityLabel: "Share focus card", action: shareCard)
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
        let renderer = ImageRenderer(content: shareCard(width: 354, height: 650, showsShadow: false))
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

    private func formattedDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            return CFLocalization.format("%.1f h", Double(minutes) / 60)
        }
        return CFLocalization.duration(minutes: minutes)
    }
}

private struct CFShareMetric: View {
    var label: String
    var value: String
    var suffix: String = ""

    var body: some View {
        VStack(spacing: CFSpacing.sm) {
            Text(CFLocalization.text(label).uppercased())
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(CFColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

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

                Text(CFLocalization.text(title))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(CFColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(CFLocalization.text(accessibilityLabel))
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

#Preview("Share Card") {
    ShareCardOverlay()
}
