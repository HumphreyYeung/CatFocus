import SwiftUI
import UserNotifications

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
    @AppStorage("trialReminderEnabled") private var trialReminderEnabled = false

    private let trialReminderRequestID = "catfocus.trial-ending-reminder"

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                CFPaywallPoseReel(height: min(200, proxy.size.height * 0.25))

                VStack(spacing: 0) {
                    VStack(spacing: CFSpacing.md) {
                        Text(headline)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .textCase(.uppercase)
                            .lineSpacing(1)
                    }

                    Spacer(minLength: CFSpacing.xl)

                    benefits

                    Spacer(minLength: CFSpacing.xl)

                    planSelector
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, CFSpacing.xl)
                .padding(.top, CFSpacing.sm)
                .padding(.bottom, CFSpacing.xl)

                VStack(spacing: CFSpacing.sm) {
                    Text("Cancel Anytime")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(CFColor.textTertiary)

                    trialReminderToggle

                    CFPrimaryButton(
                        title: purchaseSucceeded ? "Premium Unlocked" : ctaTitle,
                        isLoading: isPurchasing,
                        action: purchase
                    )

                    legalLinks
                        .padding(.top, CFSpacing.xs)
                }
                .padding(.horizontal, CFButtonLayout.primaryHorizontalInset - 32)
                .padding(.bottom, CFSpacing.lg)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CFColor.backgroundPrimary.ignoresSafeArea())
        // Keep controls in the safe area, above the media and content layers.
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.top, CFTabScreenLayout.headerTopPadding)
                .padding(.trailing, CFTabScreenLayout.horizontalPadding)
        }
        .alert("Restore Purchases", isPresented: $isRestoreAlertPresented) {
            Button("Done") {}
        } message: {
            Text(restoreMessage)
        }
        .onAppear {
            CFPaywallEventLogger.record(.paywallViewed(source: source))
            syncTrialReminderPermission()
        }
        .onChange(of: trialReminderEnabled) { _, isEnabled in
            guard !isEnabled else { return }
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [trialReminderRequestID])
        }
    }

    private var headline: String {
        switch source {
        case .premiumPose(let pose):
            return "Unlock \(pose.title)\nwith Luna"
        case .startTraining:
            return "Unlock Every Pose.\nStart Free."
        case .settings:
            return "Unlock Every Pose.\nStart Free."
        }
    }

    private var ctaTitle: String {
        switch source {
        case .startTraining: return "Start Free Trial"
        case .premiumPose: return "Unlock This Pose"
        case .settings: return "Unlock Premium"
        }
    }

    private var closeButton: some View {
        CFIconCircleButton(icon: .xmark, label: "Continue without premium") {
            CFPaywallEventLogger.record(.paywallDismissed(source: source))
            onDismiss()
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: CFSpacing.sm) {
            CFPaywallBenefitRow(title: "Unlimited focus sessions")
            CFPaywallBenefitRow(title: "All training poses and presets")
            CFPaywallBenefitRow(title: "Breaks, sounds, and progress stats")
        }
        // Match the plan column's width and inset so optical left/right edges
        // share the same reference lines instead of relying on intrinsic text width.
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, CFSpacing.xl)
        // Optical correction: the checkmark/text block reads left-heavy when
        // compared with the full-width plan cards.
        .offset(x: CFSpacing.xxl)
    }

    private var trialReminderToggle: some View {
        HStack(spacing: CFSpacing.sm) {
            HStack(spacing: CFSpacing.sm) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CFColor.textSecondary)

                Text("Remind me before trial ends")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(CFColor.textSecondary)
            }

            Spacer(minLength: CFSpacing.sm)

            Toggle("Remind me before trial ends", isOn: trialReminderBinding)
                .labelsHidden()
                .tint(CFCloudLayer.graphite)
                .scaleEffect(0.78)
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, CFSpacing.lg)
        .frame(minHeight: 44)
        .background(CFColor.surfaceWhisper)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Remind me before trial ends")
        .accessibilityValue(trialReminderEnabled ? "On" : "Off")
        .accessibilityHint("Schedules a notification one day before the three-day trial ends")
    }

    private var planSelector: some View {
        VStack(spacing: CFSpacing.md) {
            CFPaywallPlanCard(title: "Weekly Training", price: "$4.99", suffix: "/week", detail: "3 days free, then $4.99/week", badge: "3-Day Free Trial", isSelected: selectedPlan == .weekly) {
                CFPaywallEventLogger.record(.planSelected(.weekly))
                selectedPlan = .weekly
            }

            CFPaywallPlanCard(title: "Lifetime Access", price: "$49.99", suffix: "once", detail: "No recurring charge", badge: "Best Value", isSelected: selectedPlan == .lifetime) {
                CFPaywallEventLogger.record(.planSelected(.lifetime))
                selectedPlan = .lifetime
            }
        }
        .animation(
            reduceMotion ? .linear(duration: 0.01) : CFMotionCurve.componentTransition,
            value: selectedPlan
        )
    }

    private var legalLinks: some View {
        HStack(spacing: CFSpacing.lg) {
            Button("RESTORE") {
                CFPaywallEventLogger.record(.restoreAttempted)
                let restored = entitlementStore.restorePurchases()
                restoreMessage = restored
                    ? "Your premium access is active on this device."
                    : "No premium purchase was found on this device."
                isRestoreAlertPresented = true
            }
        .buttonStyle(CFPressableStyle())
            Text("•")
            Text("TERMS")
            Text("•")
            Text("PRIVACY")
        }
        .font(.system(size: 9.5, weight: .medium, design: .rounded))
        .tracking(1.1)
        .foregroundStyle(CFColor.textTertiary)
    }

    private func purchase() {
        guard !isPurchasing else { return }
        CFPaywallEventLogger.record(.purchaseStarted(selectedPlan))
        isPurchasing = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            isPurchasing = false
            guard entitlementStore.purchase(plan: selectedPlan) else { return }
            CFPaywallEventLogger.record(.purchaseSucceeded(selectedPlan))
            if selectedPlan == .weekly && trialReminderEnabled {
                scheduleTrialReminder()
            }
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

    private func scheduleTrialReminder() {
        Task {
            let notificationCenter = UNUserNotificationCenter.current()
            let isAuthorized = (try? await notificationCenter.requestAuthorization(options: [.alert, .sound])) ?? false
            guard isAuthorized else {
                await MainActor.run {
                    trialReminderEnabled = false
                }
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Your CatFocus trial ends tomorrow"
            content.body = "Review your plan before your free trial renews."
            content.sound = .default

            let twoDays: TimeInterval = 2 * 24 * 60 * 60
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: twoDays, repeats: false)
            let request = UNNotificationRequest(
                identifier: trialReminderRequestID,
                content: content,
                trigger: trigger
            )
            try? await notificationCenter.add(request)
        }
    }

    private var trialReminderBinding: Binding<Bool> {
        Binding(
            get: { trialReminderEnabled },
            set: { wantsReminder in
                guard wantsReminder else {
                    trialReminderEnabled = false
                    UNUserNotificationCenter.current()
                        .removePendingNotificationRequests(withIdentifiers: [trialReminderRequestID])
                    return
                }

                Task { @MainActor in
                    let settings = await UNUserNotificationCenter.current().notificationSettings()
                    switch settings.authorizationStatus {
                    case .authorized, .provisional, .ephemeral:
                        trialReminderEnabled = true
                    case .notDetermined:
                        let granted = (try? await UNUserNotificationCenter.current()
                            .requestAuthorization(options: [.alert, .sound])) ?? false
                        trialReminderEnabled = granted
                    case .denied:
                        trialReminderEnabled = false
                    @unknown default:
                        trialReminderEnabled = false
                    }
                }
            }
        )
    }

    private func syncTrialReminderPermission() {
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional ||
                    settings.authorizationStatus == .ephemeral else {
                trialReminderEnabled = false
                return
            }
        }
    }
}

private struct CFPaywallPoseReel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationStartDate = Date()

    var height: CGFloat

    private let tileWidth: CGFloat = 190
    private let tileGap: CGFloat = 8
    private let animationDuration: TimeInterval = 34
    private let poses = TrainingPose.allCases

    private var cycleDistance: CGFloat {
        CGFloat(poses.count) * (tileWidth + tileGap)
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { context in
                HStack(spacing: 0) {
                    ForEach(Array(0..<(poses.count * 2)), id: \.self) { index in
                        let poseIndex = index % poses.count
                        tile(for: poses[poseIndex], startDelay: Double(index) * 0.04)
                            .padding(.trailing, tileGap)
                    }
                }
                .offset(x: offset(at: context.date))
                .frame(minWidth: proxy.size.width, alignment: .leading)
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
    private func tile(for pose: TrainingPose, startDelay: TimeInterval) -> some View {
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
}

private struct CFPaywallBenefitRow: View {
    var title: String

    var body: some View {
        HStack(spacing: CFSpacing.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
        }
        .foregroundStyle(CFColor.textSecondary)
    }
}

private struct CFPaywallPlanCard: View {
    var title: String
    var price: String
    var suffix: String
    var detail: String
    var badge: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: CFSpacing.xs) {
                    Text(title.uppercased())
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(isSelected ? CFColor.textSecondary : CFColor.textTertiary)

                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text(suffix)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(CFColor.textPrimary)

                    Text(detail)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(isSelected ? CFColor.textSecondary : CFColor.textTertiary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(CFColor.borderSubtle, lineWidth: 0.8)
                        .frame(width: 25, height: 25)
                    if isSelected {
                        Circle()
                            .fill(CFCloudLayer.graphite)
                            .frame(width: 13, height: 13)
                    }
                }
            }
            .padding(.horizontal, CFSpacing.xl)
            .frame(height: 88)
            .background(CFColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .stroke(
                        isSelected ? CFCloudLayer.graphite : CFColor.borderSubtle,
                        lineWidth: isSelected ? 1.8 : 0.8
                    )
            }
            .overlay(alignment: .topTrailing) {
                Text(badge.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(CFColor.textInverse)
                    .padding(.horizontal, CFSpacing.md)
                    .frame(height: 20)
                    .background(badge == "3-Day Free Trial" ? CFColor.accentTrial : CFColor.surfaceSelected)
                    .clipShape(Capsule())
                    .offset(x: -24, y: -10)
            }
            .cfShadow(isSelected ? CFCloudLayer.selectionStrongShadow : CFCloudLayer.cardShadow)
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel(title)
    }
}
