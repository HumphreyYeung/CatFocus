import SwiftUI

struct CFPaywallScreen: View {
    @Binding var selectedPlan: OnboardingPlan
    @EnvironmentObject private var entitlementStore: CFEntitlementStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    var source: CFPaywallSource
    var userName: String
    var goalTitle: String?
    var onDismiss: () -> Void
    var onPurchaseSuccess: () -> Void
    @State private var isRestoreAlertPresented = false
    @State private var restoreMessage = ""
    @State private var isPurchasing = false
    @State private var purchaseSucceeded = false

    var body: some View {
        GeometryReader { proxy in
            let mediaHeight = min(250, proxy.size.height * 0.30)

            VStack(spacing: 0) {
                CFPaywallMediaHeader(source: source, height: mediaHeight)
                .frame(height: mediaHeight)
                .padding(.top, -proxy.safeAreaInsets.top)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        brandLockup
                            .padding(.bottom, CFSpacing.sm)

                        Text(CFLocalization.text(headline))
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.64)
                            .allowsTightening(true)
                            .foregroundStyle(CFColor.textPrimary)

                        Text(CFLocalization.text(subheadline))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(CFColor.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .padding(.top, CFSpacing.sm)
                    }
                    .padding(.bottom, CFSpacing.md)

                    HStack {
                        benefits
                            .frame(maxWidth: 320, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, CFSpacing.md)

                    VStack(spacing: CFSpacing.sm) {
                        ForEach(OnboardingPlan.allCases, id: \.self) { plan in
                            CFPaywallPlanRow(
                                plan: plan,
                                isSelected: selectedPlan == plan
                            ) {
                                selectedPlan = plan
                                CFPaywallEventLogger.record(.planSelected(plan))
                            }
                        }
                    }
                    .padding(.bottom, CFSpacing.md)

                    CFPrimaryButton(
                        title: purchaseSucceeded ? "Premium Unlocked" : "Claim Now",
                        uppercasesTitle: false,
                        isLoading: isPurchasing,
                        backgroundColor: CFColor.accentTrial,
                        foregroundColor: CFColor.textInverse,
                        showsTrailingArrow: !purchaseSucceeded,
                        action: purchase
                    )
                    .cfBreathingScale(isActive: !isPurchasing && !purchaseSucceeded)

                    legalLinks
                        .padding(.top, CFSpacing.sm)
                    }
                    .padding(.horizontal, CFSpacing.xxl)
                    .padding(.top, CFSpacing.md)
                    .padding(.bottom, max(CFSpacing.md, proxy.safeAreaInsets.bottom))
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CFColor.backgroundPrimary.ignoresSafeArea())
        .overlay(alignment: .top) {
            HStack {
                closeButton

                Spacer()

                restoreButton
            }
                .padding(.top, CFTabScreenLayout.headerTopPadding)
                .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
        }
        .alert("Restore Purchases", isPresented: $isRestoreAlertPresented) {
            Button("Done") {}
        } message: {
            Text(CFLocalization.text(restoreMessage))
        }
        .onAppear {
            selectedPlan = .annual
            CFPaywallEventLogger.record(.paywallViewed(source: source))
        }
    }

    private var headline: String {
        switch source {
        case .myCatPostcards:
            return "Unlock Every Postcard"
        case .premiumPose, .startTraining, .settings:
            return "Focus Without Limits"
        }
    }

    private var subheadline: String {
        switch source {
        case .myCatPostcards:
            return "Focus with Luna and collect every handwritten surprise."
        case .premiumPose, .startTraining, .settings:
            return "Stay focused longer with Luna by your side."
        }
    }

    private var brandLockup: some View {
        HStack(spacing: CFSpacing.sm) {
            Text("CatFocus")
                .font(.system(size: 18, weight: .black, design: .rounded))

            Text("PRO")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(CFColor.textInverse)
                .padding(.horizontal, 9)
                .frame(height: 22)
                .background(CFColor.accentTrial)
                .clipShape(Capsule())
        }
        .foregroundStyle(CFColor.textPrimary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("CatFocus Pro")
    }

    private var closeButton: some View {
        CFIconCircleButton(icon: .xmark, label: "Continue without premium") {
            CFPaywallEventLogger.record(.paywallDismissed(source: source))
            onDismiss()
        }
    }

    private var restoreButton: some View {
        Button("Restore") {
            restorePurchases()
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(CFColor.textSecondary)
        .padding(.horizontal, CFSpacing.lg)
        .frame(height: 40)
        .background(CFColor.surfacePrimary.opacity(0.9))
        .clipShape(Capsule())
        .buttonStyle(CFPressableStyle())
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: CFSpacing.sm) {
            ForEach(benefitTitles, id: \.self) { title in
                CFPaywallBenefitRow(title: title)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var benefitTitles: [String] {
        switch source {
        case .myCatPostcards:
            return [
                "Luna's complete postcard collection",
                "Unlimited Focus sessions",
                "All training poses and presets",
                "Progress stats to build better focus habits"
            ]
        case .premiumPose, .startTraining, .settings:
            return [
                "Unlimited Focus sessions",
                "All training poses and presets",
                "Collect Luna's handwritten postcards",
                "Progress stats to build better focus habits"
            ]
        }
    }

    private var legalLinks: some View {
        HStack {
            Button("Terms of Use") {
                openURL(CFLegalDocument.terms.url)
            }

            Spacer()

            Button("Privacy Policy") {
                openURL(CFLegalDocument.privacy.url)
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 10.5, weight: .medium, design: .rounded))
        .foregroundStyle(CFColor.textTertiary)
    }

    private func restorePurchases() {
        CFPaywallEventLogger.record(.restoreAttempted)
        let restored = entitlementStore.restorePurchases()
        restoreMessage = restored
            ? "Your premium access is active on this device."
            : "No premium purchase was found on this device."
        isRestoreAlertPresented = true
    }

    private func purchase() {
        guard !isPurchasing else { return }
        let plan = selectedPlan
        CFPaywallEventLogger.record(.purchaseStarted(plan))
        isPurchasing = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            isPurchasing = false
            guard entitlementStore.purchase(plan: plan) else { return }
            CFPaywallEventLogger.record(.purchaseSucceeded(plan))
            withAnimation(reduceMotion ? .linear(duration: 0.01) : CFMotionCurve.componentTransition) {
                purchaseSucceeded = true
            }
            if reduceMotion {
                onPurchaseSuccess()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    onPurchaseSuccess()
                }
            }
        }
    }
}

private struct CFPaywallPlanRow: View {
    var plan: OnboardingPlan
    var isSelected: Bool
    var action: () -> Void

    private var title: String {
        switch plan {
        case .lifetime: "Lifetime"
        case .annual: "Annually"
        case .quarterly: "Quarter"
        }
    }

    private var price: String {
        switch plan {
        case .lifetime: "$29.99"
        case .annual: "$19.99"
        case .quarterly: "$9.99"
        }
    }

    private var dailyPrice: String {
        plan == .annual ? "$0.05/day" : "$0.11/day"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: CFSpacing.md) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(isSelected ? CFColor.accentPaywall : CFColor.borderSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(CFLocalization.text(title))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(CFColor.textPrimary)

                    HStack(spacing: 4) {
                        Text(price)
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(CFColor.textTertiary)

                        if plan == .lifetime {
                            Text("·")
                                .foregroundStyle(CFColor.textTertiary)
                            Text(CFLocalization.text("One time purchase"))
                                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                .foregroundStyle(CFColor.textTertiary)
                        }
                    }
                }

                Spacer(minLength: CFSpacing.sm)

                VStack(alignment: .trailing, spacing: 3) {
                    if plan == .lifetime {
                        Text(CFLocalization.text("Best Deal"))
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(CFColor.textInverse)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(CFColor.accentPaywall)
                            .clipShape(Capsule())
                    } else {
                        Text(CFLocalization.text(dailyPrice))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? CFColor.accentPaywall : CFColor.textPrimary)
                    }
                }
            }
            .padding(.horizontal, CFSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(isSelected ? CFColor.accentPaywall.opacity(0.07) : CFColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous)
                    .stroke(isSelected ? CFColor.accentPaywall : CFColor.borderSubtle, lineWidth: isSelected ? 1.7 : 0.9)
            }
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct CFPaywallMediaHeader: View {
    var source: CFPaywallSource
    var height: CGFloat

    var body: some View {
        Group {
            if source == .myCatPostcards {
                CFPaywallPostcardHero()
            } else {
                CFPaywallPoseReel(height: height, content: .poses)
                    // The shared media canvas stays fixed so the title never
                    // moves; Pose artwork is optically lower inside its own
                    // canvas to avoid the source video's bottom white margin.
                    .offset(y: 14)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .overlay(alignment: .bottom) {
            if source == .myCatPostcards {
                LinearGradient(
                    colors: [
                        CFColor.backgroundPrimary.opacity(0),
                        CFColor.backgroundPrimary.opacity(0.28),
                        CFColor.backgroundPrimary
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: min(96, height * 0.42))
                .allowsHitTesting(false)
            }
        }
        .clipped()
    }
}

private struct CFPaywallPostcardHero: View {
    var body: some View {
        GeometryReader { proxy in
            CFPostcardArtwork.image(baseName: "CollectionPostcardHero")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .frame(maxWidth: .infinity)
        .background(CFColor.backgroundPrimary)
        .accessibilityLabel("A preview of Luna's postcard collection")
    }
}

private struct CFPaywallPoseReel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationStartDate = Date()

    var height: CGFloat
    var content: Content

    private var tileWidth: CGFloat {
        guard content == .postcards else { return 190 }
        // Keep the complete 16:9 artwork, while making the card occupy
        // approximately 95% of the reel's height instead of leaving a large
        // vertical gap inside the media area.
        return height * 0.95 * (16.0 / 9.0)
    }
    private let tileGap: CGFloat = 10
    private let animationDuration: TimeInterval = 34
    private let poses = TrainingPose.allCases
    private let postcards = (1...12).map { "CollectionPoster\(String(format: "%02d", $0))" }

    enum Content: Equatable {
        case poses
        case postcards
    }

    private var itemCount: Int {
        content == .postcards ? postcards.count : poses.count
    }

    private var cycleDistance: CGFloat {
        CGFloat(itemCount) * (tileWidth + tileGap)
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { context in
                ZStack {
                    HStack(spacing: 0) {
                        ForEach(Array(0..<(itemCount * 2)), id: \.self) { index in
                            tile(at: index, startDelay: Double(index) * 0.04)
                                .padding(.trailing, tileGap)
                        }
                    }
                    .offset(x: offset(at: context.date))
                    .frame(minWidth: proxy.size.width, alignment: .leading)

                    if content == .postcards {
                        Rectangle()
                            // A lighter material keeps the postcard silhouettes
                            // readable; the glass character comes from the
                            // layered tint and edge highlight below.
                            .fill(.ultraThinMaterial)
                            .opacity(0.48)
                            .allowsHitTesting(false)

                        LinearGradient(
                            colors: [
                                .white.opacity(0.17),
                                .white.opacity(0.07),
                                .black.opacity(0.035)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .allowsHitTesting(false)

                        Rectangle()
                            .stroke(.white.opacity(0.22), lineWidth: 0.75)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .frame(height: height)
        .clipped()
        .background(CFColor.backgroundPrimary)
        .accessibilityHidden(true)
    }

    private func offset(at date: Date) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let elapsed = max(0, date.timeIntervalSince(animationStartDate))
        let cycleTime = elapsed.truncatingRemainder(dividingBy: animationDuration)
        return -cycleDistance * CGFloat(cycleTime / animationDuration)
    }

    @ViewBuilder
    private func tile(at index: Int, startDelay: TimeInterval) -> some View {
        if content == .postcards {
            postcardTile(name: postcards[index % postcards.count])
        } else {
            let pose = poses[index % poses.count]
            poseTile(for: pose, startDelay: startDelay)
        }
    }

    @ViewBuilder
    private func poseTile(for pose: TrainingPose, startDelay: TimeInterval) -> some View {
        switch pose.catAsset {
        case .video(let name, let poster):
            CFVideoLoopView(
                videoName: name,
                posterName: poster,
                size: CGSize(width: tileWidth, height: height),
                scalingMode: .fit,
                startDelay: startDelay
            )
            .frame(width: tileWidth, height: height)
        case .staticImage, .animated:
            Color.clear
                .frame(width: tileWidth, height: height)
        }
    }

    private func postcardTile(name: String) -> some View {
        CFPostcardArtwork.image(baseName: name)
            .resizable()
            .scaledToFit()
        .frame(width: tileWidth, height: height)
    }
}

private struct CFPaywallBenefitRow: View {
    var title: String

    var body: some View {
        HStack(spacing: CFSpacing.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .black))
                .frame(width: 26, height: 26)
                .foregroundStyle(CFColor.accentTrial)
                .background(CFColor.accentTrial.opacity(0.16))
                .clipShape(Circle())
            Text(CFLocalization.text(title))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .allowsTightening(true)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(CFColor.textSecondary)
    }
}
