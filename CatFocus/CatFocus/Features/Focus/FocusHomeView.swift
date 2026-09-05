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
    private let homeCatRotationTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            header
                .cfEntrance(offset: -4)

            Color.clear
                .frame(height: CFMascotLayout.topSpacing)

            VStack(spacing: CFSpacing.xxl) {
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

                durationPill
                    .padding(.top, CFSpacing.lg)
                    .cfEntrance(delay: 0.16)
            }

            Spacer(minLength: CFSpacing.section)

            CFPrimaryButton(title: "Start", variant: .cloud, action: onStart)
                .padding(.horizontal, CFButtonLayout.primaryHorizontalInset)
                .padding(.bottom, CFMascotLayout.homePrimaryActionBottomPadding)
                .cfEntrance(delay: 0.24, offset: 12)

        }
        .background(CFColor.backgroundPrimary)
        .onAppear {
            homeCatRotation.refreshIfNeeded()
        }
        .onReceive(homeCatRotationTimer) { now in
            homeCatRotation.refreshIfNeeded(now: now)
        }
        .overlay(alignment: .bottom) {
            CFBottomTabBar(selectedTab: .focus, onSelect: onTabSelected, variant: .floating)
        }
    }

    private var header: some View {
        HStack {
            CFFitnessStatusPill(score: state.cat.fitnessScore)

            Spacer()

            CFIconCircleButton(icon: .gear, label: "Settings", action: onSettings)
        }
        .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
        .padding(.top, CFTabScreenLayout.headerTopPadding)
    }

    private var durationPill: some View {
        Button(action: onPreset) {
            HStack(spacing: CFSpacing.md) {
                CFIcon.hourglass.image
                    .font(.system(size: 16, weight: .bold))
                Text(String(format: "%02d:00", state.selectedDurationMinutes))
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                CFIcon.play.image
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(CFColor.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(CFColor.surfaceSoft)
            .clipShape(Capsule())
            .cfShadow(CFCloudLayer.cardShadow)
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel("Focus duration \(state.selectedDurationMinutes) minutes")
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
    enum Variant {
        case standard
        case floating
    }

    var selectedTab: CFAppTab
    var onSelect: (CFAppTab) -> Void = { _ in }
    var variant: Variant = .standard

    var body: some View {
        HStack(spacing: variant == .floating ? 16 : 30) {
            ForEach(CFAppTab.allCases, id: \.self) { tab in
                CFBottomTabItem(tab: tab, isSelected: tab == selectedTab, isFloating: variant == .floating) {
                    onSelect(tab)
                }
            }
        }
        .frame(maxWidth: variant == .floating ? nil : .infinity)
        .padding(.horizontal, variant == .floating ? CFSpacing.md : CFTabScreenLayout.horizontalPadding)
        .padding(.top, variant == .floating ? 10 : CFSpacing.sm)
        .padding(.bottom, variant == .floating ? 10 : CFSpacing.sm)
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
}

private struct CFBottomTabItem: View {
    var tab: CFAppTab
    var isSelected: Bool
    var isFloating: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
                    VStack(spacing: 0) {
                tab.icon.image
                    .font(.system(size: 17, weight: .bold))

                        if !isFloating {
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
            }
            .foregroundStyle(isSelected ? CFColor.textPrimary : CFColor.textTertiary)
            .frame(width: isFloating ? 42 : 68)
            .frame(minHeight: isFloating ? 42 : 48)
            .contentShape(Rectangle())
            .background {
                if isFloating && isSelected {
                    Circle()
                        .fill(CFColor.surfaceSelection)
                        .frame(width: 36, height: 36)
                }
            }
            .scaleEffect(isSelected ? 1.04 : 1)
            .animation(CFMotionCurve.instantFeedback, value: isSelected)
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel("\(tab.rawValue) tab")
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
