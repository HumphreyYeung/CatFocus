import SwiftUI

struct FocusHomeState: Equatable, Sendable {
    var cat: CatProfile
    var selectedDurationMinutes: Int

    static let preview = FocusHomeState(
        cat: .default,
        selectedDurationMinutes: 25
    )
}

struct FocusHomeView: View {
    var state: FocusHomeState
    var onStart: () -> Void = {}
    var onPreset: () -> Void = {}
    var onSettings: () -> Void = {}
    var onTabSelected: (CFAppTab) -> Void = { _ in }
    @StateObject private var homeCatRotation = CFHomeCatRotationStore()
    @State private var isHealthExplanationPresented = false
    private let homeCatRotationTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                header
                    .cfEntrance(offset: -4)

                Color.clear
                    .frame(height: CFMascotLayout.topSpacing)

                CFMascotStage {
                    CFCatScene(
                        asset: homeCatRotation.current.asset,
                        size: .focusMedia,
                        alignment: .center,
                        speech: CFSpeechBubbleConfig(
                            text: CatBubbleCatalog.message(for: CatBubbleContext(
                                health: state.cat.fitnessScore.catHealthState,
                                moment: .home
                            )),
                            alternateTexts: CatBubbleCatalog.alternateMessages(for: CatBubbleContext(
                                health: state.cat.fitnessScore.catHealthState,
                                moment: .home
                            )),
                            placement: .topTrailing,
                            offset: CGSize(width: 8, height: -8),
                            usesHandwrittenText: true,
                            usesQuietTrainingStyle: true
                        )
                    )
                }
                .cfEntrance(delay: 0.08, offset: 12)

                Spacer(minLength: CFSpacing.lg)

                sessionControlPanel
                    .padding(.horizontal, CFButtonLayout.primaryHorizontalInset)
                    .padding(.bottom, CFMascotLayout.homePrimaryActionBottomPadding)
                    .offset(y: -CFMascotLayout.homeControlsLift)
                    .cfEntrance(delay: 0.16, offset: 12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .background(CFColor.backgroundPrimary)
        }
        .onAppear {
            homeCatRotation.refreshIfNeeded()
        }
        .onReceive(homeCatRotationTimer) { now in
            homeCatRotation.refreshIfNeeded(now: now)
        }
        .sheet(isPresented: $isHealthExplanationPresented) {
            healthRulesSheet
        }
    }

    private var healthRulesSheet: some View {
        CFHealthRulesSheet(score: state.cat.fitnessScore)
    }

    private var header: some View {
        HStack {
            Button {
                isHealthExplanationPresented = true
            } label: {
                CFFitnessStatusPill(
                    score: state.cat.fitnessScore,
                    showsInfoIndicator: true
                )
            }
            .buttonStyle(CFPressableStyle())
            .accessibilityHint("Explains how Luna's health changes")

            Spacer()

            CFIconCircleButton(icon: .gear, label: "Settings", action: onSettings)
        }
        .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
        .padding(.top, CFTabScreenLayout.headerTopPadding)
    }

    private var sessionControlPanel: some View {
        VStack(spacing: 0) {
            Button(action: onPreset) {
                HStack(spacing: CFSpacing.sm) {
                    CFIcon.hourglass.image
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CFColor.textTertiary)

                    Text("Focus duration")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(CFColor.textSecondary)

                    Spacer(minLength: CFSpacing.sm)

                    Text("\(state.selectedDurationMinutes) min")
                        .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(CFColor.textPrimary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CFColor.textTertiary)
                }
                .padding(.horizontal, CFSpacing.lg)
                .frame(maxWidth: .infinity, minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(CFPressableStyle())
            .accessibilityLabel("Focus duration")
            .accessibilityValue("\(state.selectedDurationMinutes) minutes")
            .accessibilityHint("Opens training preset settings")

            CFPrimaryButton(title: "Start", variant: .cloud, action: onStart)
        }
        .background {
            RoundedRectangle(cornerRadius: CFRadius.sheet, style: .continuous)
                .fill(CFColor.surfaceWhisper)
        }
    }
}

private struct CFHealthRulesSheet: View {
    let score: FitnessScore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CFBottomSheetScaffold(
            presentationDetents: [.fraction(0.66)],
            footerBackgroundOpacity: 0.86
        ) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: CFSpacing.xs) {
                    Text("Luna's Health")
                        .font(CFFont.screenTitle)
                        .foregroundStyle(CFColor.textPrimary)

                    Text("Your current health is \(score.value)%")
                        .font(CFFont.bodySmall)
                        .foregroundStyle(CFColor.textSecondary)
                }

                Spacer(minLength: CFSpacing.md)

                CFFitnessStatusPill(score: score, showsInfoIndicator: false)
                    .fixedSize()
            }
        } content: {
            VStack(alignment: .leading, spacing: CFSpacing.xl) {
                Text("How it works")
                    .font(CFFont.cardTitle)
                    .foregroundStyle(CFColor.textPrimary)

                VStack(spacing: 0) {
                    CFHealthRuleRow(
                        icon: "bolt.fill",
                        title: "Focus to build health",
                        detail: "Every 10 Fit Points adds 1 health point."
                    )

                    Divider()

                    CFHealthRuleRow(
                        icon: "moon.zzz.fill",
                        title: "Rest affects the score",
                        detail: "After 1 rest day, inactivity lowers health by 2 each day."
                    )

                    Divider()

                    CFHealthRuleRow(
                        icon: "arrow.down.to.line",
                        title: "There is a floor",
                        detail: "Health never drops below 20%."
                    )
                }
                .padding(.horizontal, CFSpacing.lg)
                .background(CFColor.surfaceWhisper)
                .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                        .stroke(CFColor.borderSubtle, lineWidth: 0.8)
                }

                VStack(alignment: .leading, spacing: CFSpacing.sm) {
                    Text("What changes")
                        .font(CFFont.cardTitle)
                        .foregroundStyle(CFColor.textPrimary)

                    Text("Health changes Luna's mood, videos, and messages. Your letters and features are always safe.")
                        .font(CFFont.bodySmall)
                        .foregroundStyle(CFColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(CFSpacing.lg)
                .background(CFColor.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
            }
        } bottomAction: {
            CFPrimaryButton(title: "OK", action: { dismiss() })
        }
        .presentationDragIndicator(.hidden)
    }
}

private struct CFHealthRuleRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: CFSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CFColor.accentTrial)
                .frame(width: 34, height: 34)
                .background(CFColor.accentTrial.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(CFLocalization.text(title))
                    .font(CFFont.body.weight(.semibold))
                    .foregroundStyle(CFColor.textPrimary)

                Text(CFLocalization.text(detail))
                    .font(CFFont.bodySmall)
                    .foregroundStyle(CFColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, CFSpacing.lg)
    }
}

enum CFAppTab: String, CaseIterable, Equatable, Sendable {
    case focus = "Focus"
    case stats = "Stats"
    case myCat = "My Cat"

    var icon: CFIcon {
        switch self {
        case .focus:
            .focus
        case .stats:
            .stats
        case .myCat:
            .myCat
        }
    }
}

struct CFBottomTabBar: View {
    fileprivate enum Layout {
        static let itemWidth: CGFloat = 58
        static let itemHeight: CGFloat = 44
        static let selectionHeight: CGFloat = 40
        static let itemSpacing: CGFloat = CFSpacing.xs
    }

    enum Variant {
        case standard
        case floating
    }

    var selectedTab: CFAppTab
    var onSelect: (CFAppTab) -> Void = { _ in }
    var variant: Variant = .standard
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .leading) {
            if variant == .floating {
                Capsule()
                    .fill(CFColor.surfaceSelection)
                    .frame(width: Layout.itemWidth, height: Layout.selectionHeight)
                    .offset(x: floatingSelectionOffset)
                    .animation(
                        reduceMotion ? nil : CFMotionCurve.componentTransition,
                        value: floatingSelectionOffset
                    )
            }

            HStack(spacing: variant == .floating ? Layout.itemSpacing : 30) {
                ForEach(CFAppTab.allCases, id: \.self) { tab in
                    CFBottomTabItem(tab: tab, isSelected: tab == selectedTab, isFloating: variant == .floating) {
                        onSelect(tab)
                    }
                }
            }
        }
        .frame(maxWidth: variant == .floating ? nil : .infinity)
        .padding(.horizontal, variant == .floating ? CFSpacing.sm : CFTabScreenLayout.horizontalPadding)
        .padding(.vertical, CFSpacing.sm)
        .background {
            if variant == .floating {
                RoundedRectangle(cornerRadius: CFRadius.pill, style: .continuous)
                    .fill(CFColor.surfacePrimary)
                    .cfShadow(CFShadow.floating)
            }
        }
        .padding(.horizontal, variant == .floating ? CFSpacing.lg : 0)
        .padding(.bottom, variant == .floating ? CFSpacing.md : 0)
    }

    private var floatingSelectionOffset: CGFloat {
        let selectedIndex = CFAppTab.allCases.firstIndex(of: selectedTab) ?? 0
        return CGFloat(selectedIndex) * (Layout.itemWidth + Layout.itemSpacing)
    }
}

private struct CFBottomTabItem: View {
    var tab: CFAppTab
    var isSelected: Bool
    var isFloating: Bool
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                tab.icon.image
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 20, height: 20)

                if !isFloating {
                    Text(CFLocalization.text(tab.rawValue))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
            }
            .foregroundStyle(isSelected ? CFColor.textPrimary : CFColor.textTertiary)
            .frame(width: isFloating ? CFBottomTabBar.Layout.itemWidth : 68)
            .frame(height: isFloating ? CFBottomTabBar.Layout.itemHeight : 48)
            .contentShape(Rectangle())
            .scaleEffect(isSelected && !reduceMotion ? 1.04 : 1)
            .animation(reduceMotion ? nil : CFMotionCurve.instantFeedback, value: isSelected)
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel(CFLocalization.format("%@ tab", CFLocalization.text(tab.rawValue)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Focus Home") {
    FocusHomeView(state: .preview)
}

#Preview("Focus Home - Peak Form") {
    FocusHomeView(
        state: FocusHomeState(
            cat: CatProfile(name: "Luna", fitnessScore: FitnessScore(96), fitPoints: 420),
            selectedDurationMinutes: 45
        )
    )
}
