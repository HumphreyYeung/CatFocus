import SwiftUI

struct CFPaywallScreen: View {
    @Binding var selectedPlan: OnboardingPlan
    @EnvironmentObject private var entitlementStore: CFEntitlementStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var source: CFPaywallSource
    var userName: String
    var goalTitle: String?
    var onDismiss: () -> Void
    var onPurchaseSuccess: () -> Void
    @State private var isRestoreAlertPresented = false
    @State private var restoreMessage = ""
    @State private var isPurchasing = false
    @State private var purchaseSucceeded = false
    @State private var paywallShownAt = Date()
    @State private var selectedLegalDocument: CFLegalDocument?

    var body: some View {
        GeometryReader { proxy in
            let mediaHeight = min(270, proxy.size.height * 0.34)

            VStack(spacing: 0) {
                CFPaywallMediaHeader(source: source, height: mediaHeight)
                .frame(height: mediaHeight)
                .padding(.top, -proxy.safeAreaInsets.top)

                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        brandLockup
                            .padding(.bottom, CFSpacing.md)

                        Text(headline)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.64)
                            .allowsTightening(true)
                            .foregroundStyle(CFColor.textPrimary)

                        Text(subheadline)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(CFColor.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .padding(.top, CFSpacing.sm)
                    }
                    .frame(height: 120, alignment: .top)

                    HStack {
                        benefits
                            .frame(maxWidth: 320, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 148, alignment: .top)

                    Spacer(minLength: CFSpacing.md)

                    trialStatus
                        .padding(.bottom, CFSpacing.md)

                    CFPaywallTrialTimeline(
                        endDateText: trialEndDateText,
                        weeklyPrice: weeklyPrice
                    )
                    .padding(.horizontal, CFSpacing.xs)
                    .padding(.bottom, CFSpacing.lg)

                    CFPrimaryButton(
                        title: purchaseSucceeded ? "Premium Unlocked" : "$0.00 for One Week",
                        isLoading: isPurchasing,
                        showsSweep: true,
                        action: purchase
                    )

                    Text("Then \(weeklyPrice)/week. Cancel anytime.")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(CFColor.textTertiary)
                        .padding(.top, CFSpacing.sm)

                    legalLinks
                        .padding(.top, CFSpacing.md)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, CFSpacing.xxl)
                .padding(.top, CFSpacing.md)
                .padding(.bottom, max(CFSpacing.md, proxy.safeAreaInsets.bottom))
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
            Text(restoreMessage)
        }
        .sheet(item: $selectedLegalDocument) { document in
            CFLegalDocumentView(document: document)
        }
        .onAppear {
            selectedPlan = .weekly
            paywallShownAt = Date()
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

    private let weeklyPrice = "$4.99"

    private var trialEndDateText: String {
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: paywallShownAt) ?? paywallShownAt
        return endDate.formatted(.dateTime.month(.abbreviated).day().year())
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

    private var trialStatus: some View {
        HStack(spacing: CFSpacing.sm) {
            Text("7-Day Free Trial Enabled")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(CFColor.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, CFSpacing.lg)
        .frame(height: 68)
        .background(CFColor.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var legalLinks: some View {
        HStack {
            Button("Terms of Use") {
                selectedLegalDocument = .terms
            }

            Spacer()

            Button("Privacy Policy") {
                selectedLegalDocument = .privacy
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
        selectedPlan = .weekly
        CFPaywallEventLogger.record(.purchaseStarted(.weekly))
        isPurchasing = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            isPurchasing = false
            guard entitlementStore.purchase(plan: .weekly) else { return }
            CFPaywallEventLogger.record(.purchaseSucceeded(.weekly))
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
            Image("CollectionPostcardHero")
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

private struct CFPaywallTrialTimeline: View {
    var endDateText: String
    var weeklyPrice: String

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(CFColor.divider)
                .frame(width: 1.5, height: 42)
                .offset(x: 3.25)

            VStack(spacing: 18) {
                timelineRow {
                    Text("Today")
                        .font(.system(size: 14, weight: .bold, design: .rounded))

                    Spacer(minLength: CFSpacing.sm)

                    Text("7 days free")
                        .foregroundStyle(CFColor.accentSuccess)

                    Text("$0.00")
                }

                timelineRow {
                    Text("Renews \(endDateText)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer(minLength: CFSpacing.sm)

                    Text("\(weeklyPrice)/week")
                        .lineLimit(1)
                }
            }
        }
        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
        .foregroundStyle(CFColor.textPrimary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Free today. Seven days free. Renews \(endDateText) at \(weeklyPrice) per week.")
    }

    private func timelineRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: CFSpacing.md) {
            Circle()
                .fill(CFColor.borderSelected)
                .frame(width: 8, height: 8)

            HStack(alignment: .firstTextBaseline, spacing: CFSpacing.sm) {
                content()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 24)
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
        Image(name)
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
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .allowsTightening(true)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(CFColor.textSecondary)
    }
}
