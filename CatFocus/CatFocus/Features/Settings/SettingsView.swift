import SwiftUI

struct SettingsView: View {
    @Binding var focusDurationMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var sessionAlertsEnabled: Bool
    @Binding var whiteNoiseEnabled: Bool
    var hasPremiumAccess: Bool = false
    var selectedPlan: OnboardingPlan = .weekly
    @State private var selectedLegalDocument: CFLegalDocument?

    var onClose: () -> Void = {}
    var onResetStats: () -> Void = {}
    var onPremiumRequested: () -> Void = {}

    init(
        focusDurationMinutes: Binding<Int>,
        shortBreakMinutes: Binding<Int>,
        longBreakMinutes: Binding<Int>,
        sessionAlertsEnabled: Binding<Bool>,
        whiteNoiseEnabled: Binding<Bool>,
        hasPremiumAccess: Bool = false,
        selectedPlan: OnboardingPlan = .weekly,
        onClose: @escaping () -> Void = {},
        onResetStats: @escaping () -> Void = {},
        onPremiumRequested: @escaping () -> Void = {}
    ) {
        _focusDurationMinutes = focusDurationMinutes
        _shortBreakMinutes = shortBreakMinutes
        _longBreakMinutes = longBreakMinutes
        _sessionAlertsEnabled = sessionAlertsEnabled
        _whiteNoiseEnabled = whiteNoiseEnabled
        self.hasPremiumAccess = hasPremiumAccess
        self.selectedPlan = selectedPlan
        self.onClose = onClose
        self.onResetStats = onResetStats
        self.onPremiumRequested = onPremiumRequested
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: CFSpacing.xxl) {
                    if !hasPremiumAccess {
                        premiumBanner
                    }

                    settingsSection(title: "Timer Configuration") {
                        VStack(spacing: CFSpacing.lg) {
                            CFTimeOptionRow(
                                title: "Focus Duration",
                                selection: $focusDurationMinutes,
                                choices: [15, 25, 45, 60]
                            )

                            CFTimeOptionRow(
                                title: "Short Break",
                                selection: $shortBreakMinutes,
                                choices: [5, 10, 15]
                            )

                            CFTimeOptionRow(
                                title: "Long Break",
                                selection: $longBreakMinutes,
                                choices: [10, 15, 20]
                            )
                        }
                        .padding(.horizontal, CFSpacing.xl)
                        .padding(.vertical, CFSpacing.xl)
                    }

                    settingsSection(title: "Notifications & Audio") {
                        VStack(spacing: 0) {
                            CFSettingsToggleRow(
                                icon: .bell,
                                title: "Session Alerts",
                                isOn: $sessionAlertsEnabled
                            )

                            CFDividerInset()

                            CFSettingsToggleRow(
                                icon: .music,
                                title: "Background Sound",
                                isOn: $whiteNoiseEnabled
                            )
                        }
                    }

                    settingsSection(title: "About & Legal") {
                        VStack(spacing: 0) {
                            CFSettingsLinkRow(title: "Privacy Policy") {
                                selectedLegalDocument = .privacy
                            }

                            CFDividerInset()

                            CFSettingsLinkRow(title: "Terms of Use") {
                                selectedLegalDocument = .terms
                            }
                        }
                    }

                    Button(action: onResetStats) {
                        Text("Reset Cat Stats")
                            .font(CFFont.button)
                            .foregroundStyle(CFColor.accentDanger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(CFColor.accentDanger.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                                    .stroke(CFColor.accentDanger.opacity(0.26), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset Cat Stats")
                }
                .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
                .padding(.bottom, CFSpacing.xxl)
            }
        }
        .background(CFColor.backgroundPrimary)
        .sheet(item: $selectedLegalDocument) { document in
            CFLegalDocumentView(document: document)
        }
    }

    private var header: some View {
        HStack {
            CFIconCircleButton(icon: .xmark, label: "Close settings", action: onClose)

            Spacer()

            Text("Settings")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(CFColor.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 48, height: 48)
        }
        .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
        .padding(.top, CFTabScreenLayout.headerTopPadding)
        .padding(.bottom, CFTabScreenLayout.headerBottomPadding)
    }

    private var premiumBanner: some View {
        Button(action: onPremiumRequested) {
            HStack(spacing: CFSpacing.lg) {
                VStack(alignment: .leading, spacing: CFSpacing.lg) {
                    Text("Unlock Every Pose.\nStart Free.")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(CFColor.textInverse)
                        .lineSpacing(1)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("GO TO FOCUS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(CFColor.textPrimary)
                        .frame(width: 142, height: 38)
                        .background(CFColor.surfacePrimary)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(
                                    AngularGradient(
                                        colors: [
                                            Color(red: 0.26, green: 0.72, blue: 1.00),
                                            Color(red: 0.50, green: 0.34, blue: 1.00),
                                            Color(red: 0.96, green: 0.32, blue: 0.72),
                                            Color(red: 1.00, green: 0.70, blue: 0.26),
                                            Color(red: 0.36, green: 0.86, blue: 0.68),
                                            Color(red: 0.26, green: 0.72, blue: 1.00)
                                        ],
                                        center: .center
                                    ),
                                    lineWidth: 1.8
                                )
                        }
                        .shadow(color: CFCloudLayer.cardShadow.color, radius: 8, x: 0, y: 3)
                }

                Spacer(minLength: CFSpacing.md)

                Color.clear
                    .frame(width: 76, height: 88)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(CFCloudLayer.graphite)
            .overlay(alignment: .trailing) {
                Image("luna-flex-banner")
                    .resizable()
                    .scaledToFit()
                    // Crop before rotating so Luna reads as a playful peek
                    // from the edge instead of revealing the lower body.
                    .frame(width: 164, height: 164)
                    .frame(width: 142, height: 122, alignment: .topTrailing)
                    .clipped()
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white, location: 0.78),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .rotationEffect(.degrees(-45), anchor: .bottomTrailing)
                    .offset(x: 70, y: -30)
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .accessibilityLabel("Unlock every pose. Start free.")
        .accessibilityHint("Opens Pro plans")
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            CFSectionTitle(title: title)

            content()
                .background(CFColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous)
                        .stroke(CFColor.borderSubtle, lineWidth: 0.8)
                }
                .cfShadow(CFCloudLayer.cardShadow)
        }
    }
}

private struct CFSettingsLinkRow: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(CFFont.body)
                    .foregroundStyle(CFColor.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CFColor.textTertiary)
            }
            .padding(.horizontal, CFSpacing.lg)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

enum CFLegalDocument: String, Identifiable {
    case privacy
    case terms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy:
            "Privacy Policy"
        case .terms:
            "Terms of Use"
        }
    }
}

private struct CFLegalDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    var document: CFLegalDocument

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CFSpacing.lg) {
                    Text(document.title)
                        .font(CFFont.screenTitle)
                        .foregroundStyle(CFColor.textPrimary)

                    Text(document == .privacy ? privacyText : termsText)
                        .font(CFFont.body)
                        .foregroundStyle(CFColor.textSecondary)
                        .lineSpacing(5)

                    VStack(alignment: .leading, spacing: CFSpacing.sm) {
                        Text("MARKETING WEBSITE")
                            .font(CFFont.labelCaps)
                            .foregroundStyle(CFColor.textTertiary)

                        Text("The CatFocus website link will be added here.")
                            .font(CFFont.body)
                            .foregroundStyle(CFColor.textSecondary)
                    }
                    .padding(.top, CFSpacing.md)
                }
                .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
                .padding(.vertical, CFSpacing.xl)
            }
            .background(CFColor.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var privacyText: String {
        "CatFocus stores your onboarding preferences, timer settings, and training records locally on your device for the MVP. We do not send this information to a server in the current build. If analytics, accounts, or cloud sync are added later, this policy will be updated before release."
    }

    private var termsText: String {
        "CatFocus is a focus and habit companion. It is not medical advice, fitness diagnosis, or a substitute for professional care. You are responsible for choosing appropriate session settings and stopping if you feel unwell. Subscription terms, pricing, and billing will be provided through Apple before any production purchase flow is enabled."
    }
}

struct CFAppleAccountRestoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAccountFieldFocused: Bool
    @State private var accountEmail = ""
    @State private var isResultPresented = false

    private var trimmedEmail: String {
        accountEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: CFSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: CFSpacing.xs) {
                    Text("Restore Purchases")
                        .font(CFFont.cardTitle)
                        .foregroundStyle(CFColor.textPrimary)

                    Text("Sign in with the Apple Account used for CatFocus.")
                        .font(CFFont.caption)
                        .foregroundStyle(CFColor.textSecondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(CFColor.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(CFColor.surfaceSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close restore purchases")
            }

            HStack(spacing: CFSpacing.md) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .black))
                    .frame(width: 30)

                TextField("Apple Account email", text: $accountEmail)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .submitLabel(.done)
                    .focused($isAccountFieldFocused)
            }
            .font(CFFont.body)
            .padding(.horizontal, CFSpacing.lg)
            .frame(height: 54)
            .background(CFColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous)
                    .stroke(
                        CFColor.borderSubtle,
                        lineWidth: 0.8
                    )
            }
            .cfShadow(CFCloudLayer.cardShadow)

            CFPrimaryButton(title: "Continue", action: restore)
                .opacity(trimmedEmail.isEmpty ? 0.45 : 1)
                .disabled(trimmedEmail.isEmpty)
        }
        .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
        .padding(.top, CFSpacing.lg)
        .padding(.bottom, CFSpacing.xl)
        .onAppear {
            isAccountFieldFocused = true
        }
        .alert("Restore Check Complete", isPresented: $isResultPresented) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("The Apple Account was entered successfully. Live purchase restoration will be enabled after StoreKit is connected.")
        }
    }

    private func restore() {
        guard !trimmedEmail.isEmpty else { return }
        isAccountFieldFocused = false
        isResultPresented = true
    }
}

private struct CFSettingsToggleRow: View {
    var icon: CFIcon?
    var title: String
    @Binding var isOn: Bool

    init(icon: CFIcon? = nil, title: String, isOn: Binding<Bool>) {
        self.icon = icon
        self.title = title
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: CFSpacing.md) {
                if let icon {
                    icon.image
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(CFColor.textPrimary)
                        .frame(width: 20)
                }

                Text(title)
                    .font(CFFont.body)
                    .foregroundStyle(CFColor.textPrimary)
            }
        }
        .toggleStyle(.switch)
        .tint(CFColor.surfaceSelected)
        .padding(.horizontal, CFSpacing.lg)
        .frame(height: 52)
        .accessibilityLabel(title)
    }
}

private struct CFSettingsValueRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
                .font(CFFont.body)
                .foregroundStyle(CFColor.textPrimary)

            Spacer()

            Text(value)
                .font(CFFont.cardTitle)
                .foregroundStyle(CFColor.textPrimary)
        }
        .padding(.horizontal, CFSpacing.lg)
        .frame(height: 58)
    }
}

private struct CFDividerInset: View {
    var body: some View {
        Rectangle()
            .fill(CFColor.divider)
            .frame(height: 1)
    }
}

#Preview("Settings") {
    SettingsView(
        focusDurationMinutes: .constant(25),
        shortBreakMinutes: .constant(5),
        longBreakMinutes: .constant(15),
        sessionAlertsEnabled: .constant(true),
        whiteNoiseEnabled: .constant(true)
    )
}
