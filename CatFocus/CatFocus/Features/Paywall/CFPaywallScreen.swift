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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: CFSpacing.lg) {
                    closeButton
                    hero

                    VStack(spacing: CFSpacing.md) {
                        Text(headline)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .textCase(.uppercase)
                            .lineSpacing(1)

                        Text(subheadline)
                            .font(CFFont.bodySmall)
                            .foregroundStyle(CFColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    benefits
                        .padding(.top, CFSpacing.sm)
                    planSelector
                }
                .padding(.horizontal, CFSpacing.xl)
                .padding(.bottom, CFSpacing.lg)
            }

            VStack(spacing: CFSpacing.sm) {
                Text("Cancel Anytime")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(CFColor.textTertiary)

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CFColor.backgroundPrimary)
        .cfEntrance(offset: 12)
        .alert("Restore Purchases", isPresented: $isRestoreAlertPresented) {
            Button("Done") {}
        } message: {
            Text(restoreMessage)
        }
        .onAppear {
            CFPaywallEventLogger.record(.paywallViewed(source: source))
        }
    }

    private var hero: some View {
        CFCatScene(
            asset: .video(name: "luna-pose-run", poster: "luna-pose-run-poster"),
            size: .medium
        )
            // Keep the hero present, but give the copy and plans more vertical priority.
            .scaleEffect(0.84)
            .offset(y: -14)
            .frame(height: 172)
            .clipped()
            .cfEntrance(offset: 8)
    }

    private var headline: String {
        switch source {
        case .premiumPose(let pose):
            return "Unlock \(pose.title) with Luna"
        case .startTraining:
            return "Unlock Every Pose. Start Free."
        case .settings:
            return "Unlock Every Pose. Start Free."
        }
    }

    private var subheadline: String {
        switch source {
        case .premiumPose:
            return "Luna’s ready when you are."
        case .startTraining:
            let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedName.isEmpty
                ? "Luna’s ready when you are."
                : "\(trimmedName), Luna’s ready for your first full session."
        case .settings:
            return "Luna’s ready when you are."
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
        HStack {
            Spacer()
            Button {
                CFPaywallEventLogger.record(.paywallDismissed(source: source))
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(CFColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(CFColor.surfaceSoft)
                    .clipShape(Circle())
            }
            .buttonStyle(CFPressableStyle())
            .accessibilityLabel("Continue without premium")
        }
        .padding(.top, CFSpacing.sm)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: CFSpacing.md) {
            CFPaywallBenefitRow(title: "Unlimited focus sessions")
            CFPaywallBenefitRow(title: "All training poses and presets")
            CFPaywallBenefitRow(title: "Breaks, sounds, and progress stats")
        }
        .frame(maxWidth: 250, alignment: .leading)
        .padding(.vertical, CFSpacing.sm)
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

private struct CFPaywallBenefitRow: View {
    var title: String

    var body: some View {
        HStack(spacing: CFSpacing.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
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
                    .background(CFColor.surfaceSelected)
                    .clipShape(Capsule())
                    .offset(x: -24, y: -10)
            }
            .cfShadow(isSelected ? CFCloudLayer.selectionStrongShadow : CFCloudLayer.cardShadow)
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel(title)
    }
}
