import SwiftUI
import UIKit
import PencilKit
import UserNotifications

struct OnboardingFlowView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: OnboardingStep = {
        let arguments = ProcessInfo.processInfo.arguments
        let debugOptions = arguments.contains("UITEST_OPEN_ONBOARDING_OPTIONS")
            || UserDefaults.standard.bool(forKey: "debugOnboardingOptions")
        if arguments.contains("UITEST_OPEN_NOTIFICATIONS") {
            return .notifications
        }
        return debugOptions ? .problems : .greetingOne
    }()
    @State private var userName = ""
    @State private var selectedProblem: OnboardingChoice?
    @State private var selectedGoal: OnboardingChoice?
    @State private var selectedReminderTime: OnboardingReminderTime?

    @AppStorage("onboardingName") private var savedName = ""
    @AppStorage("onboardingProblemID") private var savedProblemID = ""
    @AppStorage("onboardingGoalID") private var savedGoalID = ""
    @AppStorage("onboardingSignatureData") private var savedSignatureData = Data()
    @AppStorage("onboardingReminderTimeID") private var savedReminderTimeID = ""

    var body: some View {
        ZStack {
            switch step {
            case .greetingOne:
                OnboardingStoryScene(
                    backgroundImageName: "onboarding-greeting-bg-1",
                    message: "...Wait, is someone there?",
                    bubbleWidth: 324,
                    bubbleTopRatio: 0.20
                ) {
                    go(to: .greetingTwo)
                }
            case .greetingTwo:
                OnboardingStoryScene(
                    backgroundImageName: "onboarding-greeting-bg-2",
                    message: "Oh... you caught me.",
                    bubbleWidth: 280,
                    bubbleTopRatio: 0.13
                ) {
                    go(to: .greetingThree)
                }
            case .greetingThree:
                OnboardingStoryScene(
                    backgroundImageName: "onboarding-greeting-bg-3",
                    message: "Okay... confession. I can't stop eating. Maybe I need a training partner. What's your name?",
                    bubbleWidth: 324,
                    bubbleTopRatio: 0.17
                ) {
                    go(to: .name)
                }
            case .name:
                OnboardingFormPage(
                    step: step,
                    userName: $userName,
                    selectedProblem: $selectedProblem,
                    selectedGoal: $selectedGoal,
                    onContinue: advanceFormStep
                )
            case .problems, .goal:
                OnboardingFormPage(
                    step: step,
                    userName: $userName,
                    selectedProblem: $selectedProblem,
                    selectedGoal: $selectedGoal,
                    onContinue: advanceFormStep
                )
            case .suggestion:
                OnboardingCatMessageScreen(
                    message: suggestionMessage,
                    catAsset: OnboardingLunaAsset.suggestion,
                    catSize: .onboardingHero,
                    buttonTitle: "Sounds Good"
                ) {
                    go(to: .trial)
                }
            case .trial:
                OnboardingTrialScreen {
                    go(to: .trialFinish)
                }
            case .trialFinish:
                OnboardingCatMessageScreen(
                    message: "10 seconds and I already slimmed down a tiny bit. Imagine 25 minutes...",
                    catAsset: OnboardingLunaAsset.celebrate,
                    catSize: .onboardingHero,
                    buttonTitle: "Show Me",
                    messageAreaHeight: 132,
                    showsCelebration: true
                ) {
                    go(to: .contract)
                }
            case .contract:
                OnboardingContractScreen(signatureData: $savedSignatureData) {
                    go(to: .notifications)
                }
            case .notifications:
                OnboardingReminderScreen(selectedTime: $selectedReminderTime) {
                    requestNotificationPermissionAndFinish()
                }
            }
        }
        .id(pageIdentity)
        .transition(usesQuietTransition ? CFPageTransition.quiet : CFPageTransition.forward)
        .background(CFColor.backgroundPrimary)
        .overlay(alignment: .top) {
            if step.showsProgressHeader {
                OnboardingProgressHeader(
                    currentStep: step.progressIndex,
                    totalSteps: OnboardingStep.progressTotal,
                    onBack: goBack
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .animation(pageAnimation, value: step)
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_ONBOARDING_OPTIONS") {
                step = .problems
            } else if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_ONBOARDING") {
                step = .greetingOne
            } else if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_PRETRAIN") {
                step = .trial
            } else if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_CONTRACT") {
                step = .contract
            } else if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_NOTIFICATIONS") {
                step = .notifications
            }
        }
        #endif
    }

    private var pageIdentity: String {
        switch step {
        case .name:
            "name"
        case .problems, .goal:
            "form"
        case .greetingOne:
            "greeting-one"
        case .greetingTwo:
            "greeting-two"
        case .greetingThree:
            "greeting-three"
        case .suggestion:
            "suggestion"
        case .trial:
            "trial"
        case .trialFinish:
            "trial-finish"
        case .contract:
            "contract"
        case .notifications:
            "notifications"
        }
    }

    private var pageTransition: AnyTransition {
        if usesQuietTransition {
            return .opacity
        }

        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var usesQuietTransition: Bool {
        switch step {
        case .greetingOne, .greetingTwo, .greetingThree, .name, .trialFinish:
            true
        default:
            false
        }
    }

    private var pageAnimation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.24)
    }

    private var displayName: String {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Human Friend" : trimmedName
    }

    private var suggestionMessage: String {
        let goal = selectedGoal?.title.lowercased() ?? "your focus"
        return "Hey, wait - maybe we could keep an eye on each other? You focus on \(goal), I'll train."
    }

    private func advanceFormStep() {
        switch step {
        case .name:
            go(to: .problems)
        case .problems:
            go(to: .goal)
        case .goal:
            go(to: .suggestion)
        default:
            break
        }
    }

    private func go(to nextStep: OnboardingStep) {
        withAnimation(pageAnimation) {
            step = nextStep
        }
    }

    private func goBack() {
        switch step {
        case .name:
            go(to: .greetingThree)
        case .problems:
            go(to: .name)
        case .goal:
            go(to: .problems)
        case .suggestion:
            go(to: .goal)
        case .trial:
            go(to: .suggestion)
        case .trialFinish:
            go(to: .trial)
        case .contract:
            go(to: .trialFinish)
        case .notifications:
            go(to: .contract)
        default:
            break
        }
    }

    private func finishOnboarding() {
        savedName = displayName
        savedProblemID = selectedProblem?.id ?? ""
        savedGoalID = selectedGoal?.id ?? ""
        savedReminderTimeID = selectedReminderTime?.rawValue ?? ""
        onFinish()
    }

    private func requestNotificationPermissionAndFinish() {
        savedName = displayName
        savedProblemID = selectedProblem?.id ?? ""
        savedGoalID = selectedGoal?.id ?? ""
        savedReminderTimeID = selectedReminderTime?.rawValue ?? ""

        Task { @MainActor in
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            finishOnboarding()
        }
    }
}

private enum OnboardingStep: Hashable {
    case greetingOne
    case greetingTwo
    case greetingThree
    case name
    case problems
    case goal
    case suggestion
    case trial
    case trialFinish
    case contract
    case notifications

    static let progressTotal = 8

    var showsProgressHeader: Bool {
        self != .greetingOne && self != .greetingTwo && self != .greetingThree
    }

    var progressIndex: Int {
        switch self {
        case .name: 1
        case .problems: 2
        case .goal: 3
        case .suggestion: 4
        case .trial: 5
        case .trialFinish: 6
        case .contract: 7
        case .notifications: 8
        default: 0
        }
    }
}

private enum OnboardingReminderTime: String, CaseIterable, Identifiable {
    case morning
    case midday
    case afternoon
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: "Morning · 8:00 AM"
        case .midday: "Midday · 12:30 PM"
        case .afternoon: "Afternoon · 3:00 PM"
        case .evening: "Evening · 7:00 PM"
        }
    }
}

private struct OnboardingChoice: Identifiable, Equatable {
    let id: String
    let title: String

    static let problems = [
        OnboardingChoice(id: "procrastination", title: "Procrastination"),
        OnboardingChoice(id: "phone-focus", title: "My phone won't let me focus"),
        OnboardingChoice(id: "ten-minutes", title: "I lose focus in 10 minutes"),
        OnboardingChoice(id: "habit", title: "I want to build a habit"),
        OnboardingChoice(id: "adhd", title: "ADHD")
    ]

    static let goals = [
        OnboardingChoice(id: "work", title: "Work"),
        OnboardingChoice(id: "meditation", title: "Meditation"),
        OnboardingChoice(id: "reading", title: "Reading"),
        OnboardingChoice(id: "study", title: "Study"),
        OnboardingChoice(id: "else", title: "Something else")
    ]
}

enum OnboardingPlan: String, Equatable {
    case weekly
    case lifetime
}

private enum OnboardingLunaAsset {
    static let guide = CFCatAsset.staticImage(name: "luna-onboarding-guide")
    static let suggestion = CFCatAsset.staticImage(name: "luna-onboarding-suggestion")
    static let trial = CFCatAsset.staticImage(name: "luna-onboarding-trial")
    static let celebrate = CFCatAsset.staticImage(name: "luna-onboarding-celebrate")
    static let pact = CFCatAsset.staticImage(name: "luna-onboarding-pact")
    static let paywall = CFCatAsset.staticImage(name: "luna-paywall-plan")
}

private struct OnboardingStoryScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bubbleAppeared = false

    var backgroundImageName: String
    var message: String
    var bubbleWidth: CGFloat
    var bubbleTopRatio: CGFloat
    var onContinue: () -> Void

    var body: some View {
        Button(action: onContinue) {
            GeometryReader { proxy in
                ZStack {
                    OnboardingStoryBackground(imageName: backgroundImageName)

                    VStack(spacing: 0) {
                        OnboardingDialogueBubble(text: message)
                            .frame(width: min(bubbleWidth, proxy.size.width - 32))
                            .padding(.top, proxy.size.height * bubbleTopRatio)
                            .scaleEffect(bubbleAppeared || reduceMotion ? 1 : 0.97)
                            .opacity(bubbleAppeared || reduceMotion ? 1 : 0)

                        Spacer()

                        OnboardingStoryCTA()
                            .padding(.bottom, max(128, proxy.safeAreaInsets.bottom + 126))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .accessibilityLabel("Tap to continue")
        .onAppear {
            guard !reduceMotion else {
                bubbleAppeared = true
                return
            }
            withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
                bubbleAppeared = true
            }
        }
    }
}

private struct OnboardingStoryBackground: View {
    var imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }
}

private struct OnboardingStoryCTA: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    var body: some View {
        Text("TAP TO CONTINUE")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .tracking(3.2)
            .foregroundStyle(CFColor.textInverse.opacity(0.92))
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Color.black.opacity(0.42))
            .scaleEffect(isBreathing && !reduceMotion ? 1.025 : 1)
            .opacity(isBreathing && !reduceMotion ? 0.88 : 1)
            .animation(
                reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 1.25).repeatForever(autoreverses: true),
                value: isBreathing
            )
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                isBreathing = true
            }
    }
}

private struct OnboardingProgressHeader: View {
    var currentStep: Int
    var totalSteps: Int
    var onBack: () -> Void

    private var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }

    var body: some View {
        HStack(spacing: CFSpacing.md) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(CFColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(CFColor.surfaceSoft)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CFColor.borderSubtle)

                    Capsule()
                        .fill(CFColor.surfaceSelected)
                        .frame(width: proxy.size.width * progress)
                }
                .frame(height: 5)
            }
            .frame(height: 5)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Onboarding progress")
            .accessibilityValue("Step \(currentStep) of \(totalSteps)")

            Text("\(currentStep)/\(totalSteps)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(CFColor.textTertiary)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, CFButtonLayout.primaryHorizontalInset - 32)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(CFColor.backgroundPrimary.opacity(0.96))
    }
}

private struct OnboardingFormPage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isNameFieldFocused: Bool
    var step: OnboardingStep
    @Binding var userName: String
    @Binding var selectedProblem: OnboardingChoice?
    @Binding var selectedGoal: OnboardingChoice?
    var onContinue: () -> Void

    var body: some View {
        OnboardingFormScaffold(
            message: message,
            actionTitle: "Continue",
            isActionDisabled: isActionDisabled,
            onAction: onContinue
        ) {
            ZStack(alignment: .leading) {
                switch step {
                case .name:
                    nameField
                        .id(step)
                        .transition(formContentTransition)
                case .problems, .goal:
                    choiceList
                        .id(step)
                        .transition(formContentTransition)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 378)
            .clipped()
        }
        .animation(reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.24), value: step)
        .onChange(of: step) { _, newStep in
            if newStep != .name {
                isNameFieldFocused = false
            }
        }
    }

    private var formContentTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var message: String {
        switch step {
        case .name:
            "A training partner sounds nice. What should I call you?"
        case .problems:
            "Got something you can't quite handle either?"
        case .goal:
            "What do you want to focus on?"
        default:
            ""
        }
    }

    private var isActionDisabled: Bool {
        switch step {
        case .name:
            userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .problems:
            selectedProblem == nil
        case .goal:
            selectedGoal == nil
        default:
            true
        }
    }

    private var nameField: some View {
        TextField("ENTER YOUR NAME", text: $userName)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .tracking(0.9)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.continue)
            .focused($isNameFieldFocused)
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding(.horizontal, CFSpacing.lg)
            .background(CFColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous)
                    .strokeBorder(
                        isNameFieldFocused ? CFColor.surfaceSelected : CFColor.borderPrimary,
                        lineWidth: 2
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous))
            .simultaneousGesture(
                TapGesture().onEnded {
                    isNameFieldFocused = true
                }
            )
            .onSubmit {
                if !isActionDisabled {
                    onContinue()
                }
            }
    }

    @ViewBuilder
    private var choiceList: some View {
        VStack(spacing: CFSpacing.lg) {
            ForEach(choices) { choice in
                OnboardingChoiceButton(
                    title: choice.title,
                    isSelected: selectedChoice == choice
                ) {
                    selectedChoiceBinding.wrappedValue = choice
                }
            }
        }
        .padding(.horizontal, CFSpacing.md)
        .padding(.vertical, CFSpacing.sm)
        .background(Color.clear)
    }

    private var choices: [OnboardingChoice] {
        step == .problems ? OnboardingChoice.problems : OnboardingChoice.goals
    }

    private var selectedChoiceBinding: Binding<OnboardingChoice?> {
        step == .problems ? $selectedProblem : $selectedGoal
    }

    private var selectedChoice: OnboardingChoice? {
        get { step == .problems ? selectedProblem : selectedGoal }
        set { selectedChoiceBinding.wrappedValue = newValue }
    }
}

private struct OnboardingCatMessageScreen: View {
    var message: String
    var catAsset: CFCatAsset
    var catSize: CFCatAssetSize
    var buttonTitle: String
    var messageAreaHeight: CGFloat?
    var showsCelebration = false
    var onContinue: () -> Void

    var body: some View {
        OnboardingPlainScaffold(actionTitle: buttonTitle, onAction: onContinue) {
            Spacer(minLength: 76)

            VStack(spacing: CFSpacing.xl) {
                ZStack(alignment: .top) {
                    // Reserve the final bubble height so the typewriter effect never
                    // moves Luna while the message is being revealed.
                    OnboardingDialogueBubble(text: message, animateTyping: false)
                        .frame(maxWidth: 300)
                        .opacity(0)
                        .accessibilityHidden(true)

                    OnboardingDialogueBubble(text: message)
                        .frame(maxWidth: 300)
                }
                .frame(maxWidth: .infinity, minHeight: messageAreaHeight ?? 0, alignment: .top)

                CFCatHero(asset: catAsset, size: catSize)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 80)
        }
        .overlay {
            if showsCelebration {
                CFConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct OnboardingReminderScreen: View {
    @Binding var selectedTime: OnboardingReminderTime?
    var onConfirm: () -> Void

    var body: some View {
        OnboardingPlainScaffold(
            actionTitle: selectedTime == nil ? "Choose a Time" : "Let Luna Remind Me",
            isActionDisabled: selectedTime == nil,
            onAction: onConfirm
        ) {
            Spacer(minLength: 76)

            VStack(spacing: CFSpacing.xl) {
                HStack(alignment: .top, spacing: CFSpacing.md) {
                    CFCatHero(asset: OnboardingLunaAsset.guide, size: .onboardingCompact)

                    OnboardingDialogueBubble(
                        text: "When should I nudge you to focus?",
                        direction: .leading
                    )
                    .frame(maxWidth: .infinity)
                }

                VStack(spacing: CFSpacing.md) {
                    ForEach(OnboardingReminderTime.allCases) { time in
                        Button {
                            withAnimation(.easeOut(duration: 0.18)) {
                                selectedTime = time
                            }
                        } label: {
                            HStack(spacing: CFSpacing.md) {
                                Text(time.title)
                                    .font(.system(
                                        size: 15,
                                        weight: selectedTime == time ? .bold : .semibold,
                                        design: .rounded
                                    ))
                                    .tracking(0.3)
                                    .foregroundStyle(CFCloudLayer.graphite)

                                Spacer()
                            }
                            .padding(.horizontal, CFSpacing.lg)
                            .frame(maxWidth: .infinity, minHeight: 66)
                            .background(CFColor.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous)
                                    .stroke(
                                        selectedTime == time ? CFCloudLayer.graphite : CFColor.borderSubtle,
                                        lineWidth: selectedTime == time ? 1.8 : 0.8
                                    )
                            }
                            .cfShadow(selectedTime == time ? CFCloudLayer.selectionStrongShadow : CFCloudLayer.cardShadow)
                        }
                        .buttonStyle(OnboardingPressButtonStyle())
                        .accessibilityLabel(time.title)
                        .accessibilityAddTraits(selectedTime == time ? .isSelected : [])
                    }
                }
            }
            .padding(.horizontal, CFButtonLayout.primaryHorizontalInset - 32)

            Spacer(minLength: 24)
        }
    }
}

private struct OnboardingTrialScreen: View {
    var onComplete: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPose: TrainingPose = .default
    @State private var elapsedSeconds: TimeInterval = 0
    @State private var dragOffset: CGFloat = 0

    private let poses = TrainingPose.allCases

    var body: some View {
        OnboardingPlainScaffold {
            Spacer(minLength: 76)

            VStack(spacing: CFSpacing.xl) {
                ZStack(alignment: .top) {
                    // Keep the final message height reserved while the typewriter
                    // reveals the text, so the pose carousel and Luna stay fixed.
                    OnboardingDialogueBubble(
                        text: "Let's start with a brief pre-training - hold the button for 10 seconds.",
                        animateTyping: false
                    )
                    .frame(maxWidth: 300)
                    .opacity(0)
                    .accessibilityHidden(true)

                    OnboardingDialogueBubble(
                        text: "Let's start with a brief pre-training - hold the button for 10 seconds."
                    )
                    .frame(maxWidth: 300)
                }

                poseCarousel
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 28)

            Text(timeLabel)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(CFColor.textSecondary)

            OnboardingHoldButton(elapsedSeconds: $elapsedSeconds, onComplete: onComplete)
                .padding(.top, CFSpacing.lg)
                .padding(.bottom, 38)
        }
    }

    private var timeLabel: String {
        String(format: "00:%02d", min(Int(elapsedSeconds), 10))
    }

    private var poseCarousel: some View {
        VStack(spacing: CFSpacing.md) {
            ZStack {
                // Keep the selected Pose centered while giving the neighboring
                // Poses enough visual presence to communicate that this is a
                // carousel. The scale and offset animate together so the next
                // Pose grows into the hero position rather than simply swapping.
                ForEach(Array(poses.enumerated()), id: \.element) { index, pose in
                    CFCatHero(
                        asset: index == selectedPoseIndex
                            ? pose.catAsset
                            : .staticImage(name: pose.posterAssetName),
                        size: .onboardingHero
                    )
                        .frame(width: poseSlotWidth, height: poseSlotWidth)
                        .scaleEffect(poseScale(for: index))
                        .opacity(poseOpacity(for: index))
                        .offset(x: CGFloat(index - selectedPoseIndex) * carouselStride + dragOffset * 0.22)
                        .zIndex(index == selectedPoseIndex ? 1 : 0)
                        .animation(poseSwitchAnimation, value: selectedPoseIndex)
                }

                HStack {
                    poseSwipeHint(systemName: "arrow.left", accessibilityLabel: "Next pose") {
                        selectPose(by: 1)
                    }

                    Spacer()

                    if selectedPoseIndex > 0 {
                        poseSwipeHint(systemName: "arrow.right", accessibilityLabel: "Previous pose") {
                            selectPose(by: -1)
                        }
                    }
                }
                .padding(.horizontal, 14)
            }
            .frame(width: poseCarouselWidth, height: poseSlotWidth)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        selectPose(from: value.translation.width)
                    }
            )

            HStack(spacing: CFSpacing.sm) {
                ForEach(poses) { pose in
                    Circle()
                        .fill(pose == selectedPose ? CFColor.surfaceSelected : CFColor.borderSubtle)
                        .frame(width: pose == selectedPose ? 7 : 5, height: pose == selectedPose ? 7 : 5)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pre-training pose")
            .accessibilityValue(selectedPose.title)
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier("pretrainingPose")
        .accessibilityHint("Swipe left or right to choose a pose")
    }

    private var poseSlotWidth: CGFloat {
        CFCatAssetSize.onboardingHero.frame.width
    }

    private var poseCarouselWidth: CGFloat {
        390
    }

    private var carouselStride: CGFloat {
        210
    }

    private func poseScale(for index: Int) -> CGFloat {
        index == selectedPoseIndex ? 0.88 : 0.52
    }

    private func poseOpacity(for index: Int) -> Double {
        index == selectedPoseIndex ? 1 : 0.56
    }

    private var poseSwitchAnimation: Animation {
        reduceMotion
            ? .linear(duration: 0.01)
            : .spring(response: 0.34, dampingFraction: 0.94)
    }

    private var selectedPoseIndex: Int {
        poses.firstIndex(of: selectedPose) ?? 0
    }

    private func poseSwipeHint(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(CFColor.textSecondary.opacity(0.42))
                .frame(width: 34, height: 34)
                .background(CFColor.surfaceSoft.opacity(0.72), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to change the pre-training pose")
    }

    private func selectPose(from translation: CGFloat) {
        guard abs(translation) > 40 else {
            settleDrag()
            return
        }

        selectPose(by: translation < 0 ? 1 : -1)
    }

    private func selectPose(by offset: Int) {
        guard let currentIndex = poses.firstIndex(of: selectedPose) else { return }

        let nextIndex = min(max(currentIndex + offset, 0), poses.count - 1)

        guard nextIndex != currentIndex else {
            settleDrag()
            return
        }

        withAnimation(poseSwitchAnimation) {
            selectedPose = poses[nextIndex]
            dragOffset = 0
        }
    }

    private func settleDrag() {
        withAnimation(poseSwitchAnimation) {
            dragOffset = 0
        }
    }
}

private struct OnboardingContractScreen: View {
    @Binding var signatureData: Data
    var onAccept: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSignatureSheetPresented = false
    @State private var isSignatureVisible = false
    @State private var isPawSealVisible = false
    @State private var shouldPulseSealButton = false
    @State private var sealAnimationTask: Task<Void, Never>?
    @State private var pawSoundPlayer = CFPawSoundPlayer()

    private var hasSignature: Bool {
        !signatureData.isEmpty
    }

    var body: some View {
        OnboardingPlainScaffold(
            actionTitle: hasSignature ? "Seal the Pact" : "Sign Above to Continue",
            actionPulse: shouldPulseSealButton,
            onAction: handlePrimaryAction
        ) {
            Spacer(minLength: 92)

                HStack(alignment: .top, spacing: CFSpacing.md) {
                    CFCatHero(asset: OnboardingLunaAsset.pact, size: .onboardingCompact)
                OnboardingDialogueBubble(text: "So... shall we make a pact?", direction: .leading)
                    .frame(maxWidth: 210)
            }

            Button(action: handlePrimaryAction) {
                OnboardingContractCard(
                    signatureData: signatureData,
                    isSignatureVisible: isSignatureVisible,
                    isPawSealVisible: isPawSealVisible
                )
            }
            .buttonStyle(OnboardingPressButtonStyle())
            .accessibilityLabel(hasSignature ? "Seal the Pact" : "Sign the Pact")
            .accessibilityHint(hasSignature ? "Complete the pact" : "Open the signature panel")
            .padding(.top, CFSpacing.xl)
            .cfEntrance(delay: 0.10, offset: 10)

            Spacer(minLength: 70)
        }
        .sheet(isPresented: $isSignatureSheetPresented) {
            OnboardingSignatureSheet { data in
                confirmSignature(data)
            }
            .presentationDetents([.height(430)])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if hasSignature {
                isSignatureVisible = true
                isPawSealVisible = true
            }
        }
        .onDisappear {
            sealAnimationTask?.cancel()
            pawSoundPlayer.stop()
        }
    }

    private func handlePrimaryAction() {
        if hasSignature {
            onAccept()
        } else {
            isSignatureSheetPresented = true
        }
    }

    private func confirmSignature(_ data: Data) {
        signatureData = data
        isSignatureSheetPresented = false
        isSignatureVisible = false
        isPawSealVisible = false

        withAnimation(reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.28)) {
            isSignatureVisible = true
        }

        sealAnimationTask?.cancel()
        sealAnimationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 140_000_000)
            guard !Task.isCancelled else { return }

            withAnimation(reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.25)) {
                isPawSealVisible = true
            }
            pawSoundPlayer.play()

            guard !reduceMotion else { return }
            withAnimation(CFMotionCurve.celebration) {
                shouldPulseSealButton = true
            }
            try? await Task.sleep(nanoseconds: 420_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(CFMotionCurve.componentTransition) {
                shouldPulseSealButton = false
            }
        }
    }
}

private struct OnboardingSignatureSheet: View {
    var onConfirm: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var drawing = PKDrawing()

    private var hasInk: Bool {
        !drawing.strokes.isEmpty
    }

    var body: some View {
        VStack(spacing: CFSpacing.lg) {
            VStack(spacing: CFSpacing.sm) {
                Text("SIGN THE PACT")
                    .font(CFFont.sectionTitle)
                    .tracking(1.4)
                    .foregroundStyle(CFColor.textPrimary)

                Text("Put your name on it.")
                    .font(CFFont.bodySmall)
                    .foregroundStyle(CFColor.textSecondary)
            }

            OnboardingSignatureCanvas(drawing: $drawing)
                .frame(height: 170)
                .background(CFColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous)
                        .strokeBorder(CFColor.borderSubtle, lineWidth: 1)
                }

            HStack(spacing: CFSpacing.md) {
                OnboardingSignatureActionButton(title: "CLEAR", isProminent: false, isDisabled: false) {
                    drawing = PKDrawing()
                }

                OnboardingSignatureActionButton(
                    title: "CONFIRM SIGNATURE",
                    isProminent: true,
                    isDisabled: !hasInk
                ) {
                    let bounds = drawing.bounds.insetBy(dx: -20, dy: -20)
                    let image = drawing.image(from: bounds, scale: 3)
                    guard let data = image.pngData() else { return }
                    onConfirm(data)
                }
            }
        }
        .padding(.horizontal, CFSpacing.xl)
        .padding(.top, CFSpacing.lg)
        .padding(.bottom, CFSpacing.xl)
    }
}

private struct OnboardingSignatureActionButton: View {
    let title: String
    let isProminent: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(isProminent ? CFColor.textInverse : CFColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 46)
                .padding(.horizontal, CFSpacing.sm)
                .background(isProminent ? CFCloudLayer.graphite : CFColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: CFRadius.button, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CFRadius.button, style: .continuous)
                        .strokeBorder(isProminent ? CFCloudLayer.graphite : CFColor.borderSelected, lineWidth: isProminent ? 0 : 1.0)
                }
                .cfShadow(isProminent ? CFCloudLayer.selectedShadow : CFCloudLayer.cardShadow)
                .opacity(isDisabled ? 0.38 : 1)
        }
        .buttonStyle(CFPressableStyle())
        .disabled(isDisabled)
        .accessibilityLabel(title.capitalized)
    }
}

private struct OnboardingSignatureCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        private var drawing: Binding<PKDrawing>

        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing.wrappedValue = canvasView.drawing
        }
    }
}

private struct OnboardingFormScaffold<Content: View>: View {
    var message: String
    var actionTitle: String
    var isActionDisabled: Bool = false
    var onAction: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: CFSpacing.md) {
                    CFCatHero(asset: OnboardingLunaAsset.guide, size: .onboardingCompact)
                    OnboardingDialogueBubble(text: message, direction: .leading)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 72)

                Spacer(minLength: CFSpacing.xl)

                ScrollView(.vertical, showsIndicators: false) {
                    content
                }
                .scrollDismissesKeyboard(.interactively)

                Spacer(minLength: CFSpacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, CFButtonLayout.primaryHorizontalInset - 32)

            CFPrimaryButton(
                title: actionTitle,
                icon: nil,
                isDisabled: isActionDisabled,
                variant: .cloud,
                action: onAction
            )
            .padding(.horizontal, CFButtonLayout.primaryHorizontalInset - 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CFColor.backgroundPrimary)
    }
}

struct OnboardingPlainScaffold<Content: View>: View {
    var actionTitle: String?
    var actionIcon: String?
    var isActionDisabled: Bool
    var actionPulse: Bool
    var onAction: () -> Void
    @ViewBuilder var content: Content

    init(
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        isActionDisabled: Bool = false,
        actionPulse: Bool = false,
        onAction: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.isActionDisabled = isActionDisabled
        self.actionPulse = actionPulse
        self.onAction = onAction
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    content
                }
                .scrollDismissesKeyboard(.interactively)

            if actionTitle != nil {
                Spacer(minLength: CFSpacing.xl)
            }

            if let actionTitle {
                CFPrimaryButton(
                    title: actionTitle,
                    icon: nil,
                    isDisabled: isActionDisabled,
                    action: onAction
                )
                .overlay(alignment: .center) {
                    if let actionIcon {
                        HStack {
                            Spacer()
                            Image(systemName: actionIcon)
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(isActionDisabled ? CFColor.textInverse.opacity(0.5) : CFColor.textInverse)
                                .padding(.trailing, 28)
                        }
                    }
                }
                .padding(.horizontal, CFButtonLayout.primaryHorizontalInset - 32)
                .padding(.bottom, 48)
                .scaleEffect(actionPulse ? 1.02 : 1)
                .animation(CFMotionCurve.celebration, value: actionPulse)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CFColor.backgroundPrimary)
    }
}

private struct OnboardingDialogueBubble: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var text: String
    var direction: OnboardingBubbleDirection = .bottom
    var animateTyping = true
    @State private var displayedText = ""
    @State private var typingTask: Task<Void, Never>?

    var body: some View {
        Text(displayedText.isEmpty ? " " : displayedText)
            .font(CFFont.pactHandwritten)
            .foregroundStyle(CFCloudLayer.graphite.opacity(0.88))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, CFSpacing.lg)
            .padding(.vertical, CFSpacing.md)
            .padding(.bottom, direction == .bottom ? 12 : 0)
            .padding(.leading, direction == .leading ? 12 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentTransition(.opacity)
            .background {
                OnboardingBubbleShape(direction: direction)
                    .fill(CFColor.surfacePrimary)
                    .overlay {
                        OnboardingBubbleShape(direction: direction)
                            .stroke(CFCloudLayer.hairline, lineWidth: 0.8)
                    }
                    .cfShadow(CFCloudLayer.cardShadow)
            }
            .animation(
                reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.2),
                value: text
            )
            .onAppear {
                startTyping()
            }
            .onChange(of: text) { _, _ in
                startTyping()
            }
            .onDisappear {
                typingTask?.cancel()
            }
    }

    private func startTyping() {
        typingTask?.cancel()

        guard animateTyping else {
            displayedText = text
            return
        }

        guard !reduceMotion else {
            displayedText = text
            return
        }

        displayedText = ""
        typingTask = Task { @MainActor in
            for character in text {
                guard !Task.isCancelled else { return }
                displayedText.append(character)
                try? await Task.sleep(nanoseconds: 18_000_000)
            }
        }
    }
}

private enum OnboardingBubbleDirection {
    case bottom
    case leading
}

struct OnboardingPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(
                reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct OnboardingChoiceButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 13.5, weight: isSelected ? .bold : .semibold, design: .rounded))
                .tracking(0.45)
                .foregroundStyle(CFCloudLayer.graphite)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, minHeight: 66)
                .padding(.horizontal, CFSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                        .fill(CFColor.surfacePrimary)
                        .cfShadow(isSelected ? CFCloudLayer.selectedShadow : CFCloudLayer.cardShadow)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                        .strokeBorder(
                            isSelected ? CFCloudLayer.graphite : CFCloudLayer.hairline,
                            lineWidth: isSelected ? 1.8 : 0.8
                        )
                }
                .scaleEffect(isSelected ? 1.008 : 1)
                .animation(CFMotionCurve.componentTransition, value: isSelected)
        }
        .buttonStyle(OnboardingPressButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct CFConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> CFConfettiEmitterView {
        CFConfettiEmitterView()
    }

    func updateUIView(_ uiView: CFConfettiEmitterView, context: Context) {}
}

final class CFConfettiEmitterView: UIView {
    private var emitters: [CAEmitterLayer] = []
    private var didStart = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !didStart, bounds.width > 0 {
            startConfetti()
        }
    }

    private func startConfetti() {
        didStart = true

        let emitter = CAEmitterLayer()
        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -8)
        emitter.emitterSize = CGSize(width: bounds.width * 0.86, height: 1)
        emitter.emitterShape = .line
        emitter.emitterMode = .surface
        emitter.renderMode = .unordered
        emitter.emitterCells = emitterCells(xAcceleration: 0)
        emitter.birthRate = 1
        layer.addSublayer(emitter)
        emitters = [emitter]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.emitters.forEach { $0.birthRate = 0 }
        }
    }

    private func emitterCells(xAcceleration: CGFloat) -> [CAEmitterCell] {
        let colors: [UIColor] = [
            .black,
            .systemRed,
            UIColor(red: 0.35, green: 0.42, blue: 0.85, alpha: 1),
            UIColor(red: 0.92, green: 0.58, blue: 0.18, alpha: 1)
        ]
        let shapes: [ConfettiShape] = [.rectangle, .circle, .diamond]

        return colors.enumerated().flatMap { index, color in
            shapes.map { shape in
                let cell = CAEmitterCell()
                cell.contents = confettiImage(color: color, shape: shape).cgImage
                cell.contentsScale = UIScreen.main.scale
                cell.birthRate = index == 0 ? 10 : 7
                cell.lifetime = 3.4
                cell.lifetimeRange = 0.8
                cell.velocity = 230
                cell.velocityRange = 95
                cell.emissionLongitude = .pi
                cell.emissionRange = .pi / 6
                cell.xAcceleration = xAcceleration
                cell.yAcceleration = 115
                cell.spin = 4
                cell.spinRange = 7
                cell.scale = shape == .circle ? 0.75 : 0.58
                cell.scaleRange = 0.3
                cell.alphaRange = 0.18
                cell.alphaSpeed = -0.18
                return cell
            }
        }
    }

    private func confettiImage(color: UIColor, shape: ConfettiShape) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 16))
        return renderer.image { context in
            color.setFill()
            let rect = CGRect(x: 1, y: 1, width: 8, height: 14)
            switch shape {
            case .rectangle:
                context.fill(rect)
            case .circle:
                UIBezierPath(ovalIn: CGRect(x: 1, y: 4, width: 8, height: 8)).fill()
            case .diamond:
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 5, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 8))
                path.addLine(to: CGPoint(x: 5, y: 16))
                path.addLine(to: CGPoint(x: 0, y: 8))
                path.close()
                path.fill()
            }
        }
    }

    private enum ConfettiShape {
        case rectangle
        case circle
        case diamond
    }
}

private struct OnboardingHoldButton: View {
    @Binding var elapsedSeconds: TimeInterval
    var onComplete: () -> Void

    @State private var isPressing = false
    @State private var didComplete = false
    @State private var pressStartedAt: Date?
    @State private var completionTask: Task<Void, Never>?

    private let requiredDuration: TimeInterval = 10

    var body: some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .stroke(CFColor.borderSubtle, lineWidth: 5)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(CFColor.surfaceSelected, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .fill(CFColor.surfaceSelected)
                    .frame(width: 128, height: 128)
                    .overlay {
                        Text("HOLD")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(CFColor.textInverse)
                    }
                    .scaleEffect(isPressing ? 0.94 : 1)
                    .cfShadow(CFShadow.cta)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.76), value: isPressing)
        }
        .buttonStyle(OnboardingPressButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    beginPressIfNeeded()
                }
                .onEnded { _ in
                    endPress()
                }
        )
        .onDisappear {
            completionTask?.cancel()
        }
        .accessibilityLabel("Hold to train")
        .accessibilityValue(isPressing ? "\(Int(elapsedSeconds.rounded(.down))) seconds" : "Ready")
    }

    private var progress: CGFloat {
        CGFloat(min(elapsedSeconds / requiredDuration, 1))
    }

    private func beginPressIfNeeded() {
        guard !isPressing, !didComplete else { return }

        isPressing = true
        pressStartedAt = Date()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        completionTask = Task { @MainActor in
            while !Task.isCancelled {
                guard let pressStartedAt else { return }
                let elapsed = min(Date().timeIntervalSince(pressStartedAt), requiredDuration)
                elapsedSeconds = elapsed

                if elapsed >= requiredDuration {
                    didComplete = true
                    isPressing = false
                    completionTask = nil
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onComplete()
                    return
                }

                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    private func endPress() {
        guard isPressing else { return }

        completionTask?.cancel()
        completionTask = nil
        isPressing = false
        pressStartedAt = nil

        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            elapsedSeconds = 0
        }
    }
}

private struct OnboardingContractCard: View {
    var signatureData: Data
    var isSignatureVisible: Bool
    var isPawSealVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PAWSOME PACT")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundStyle(CFColor.textSecondary)
                    .padding(.horizontal, CFSpacing.md)
                    .frame(height: 24)
                    .background(CFColor.surfaceSoft)
                    .clipShape(Capsule())
                Spacer()
                Text("19 June 2026")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(CFColor.textTertiary)
            }
            .padding(CFSpacing.xl)

            Divider()

            VStack(alignment: .leading, spacing: CFSpacing.lg) {
                Text("I promise Luna my full focus. Every focused minute helps her grow.")
                    .font(CFFont.pactHandwritten)
                    .lineSpacing(6)

                Text("MY PROMISE TO LUNA:")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(CFColor.textTertiary)

                VStack(alignment: .leading, spacing: CFSpacing.sm) {
                    Text("• I show up fully for each session.")
                    Text("• Luna's strength is in my hands.")
                }
                .font(CFFont.pactHandwrittenSmall)
                .foregroundStyle(CFColor.textPrimary)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: CFSpacing.sm) {
                        Text("YOU SIGN HERE")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(CFColor.textTertiary)
                        Group {
                            if let image = UIImage(data: signatureData), !signatureData.isEmpty {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 132, height: 48)
                                    .scaleEffect(isSignatureVisible ? 1 : 0.92)
                                    .opacity(isSignatureVisible ? 1 : 0)
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: 132, height: 48)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: CFSpacing.sm) {
                        Text("LUNA'S SEAL")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(CFColor.textTertiary)
                        CFInkPawSeal()
                            .frame(width: 132, height: 48, alignment: .center)
                            .scaleEffect(isPawSealVisible ? 1 : 0.35)
                            .opacity(isPawSealVisible ? 1 : 0)
                    }
                }
                .padding(.top, CFSpacing.md)
            }
            .padding(CFSpacing.xl)
        }
        .frame(maxWidth: 318)
        .background(CFColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .cfShadow(CFShadow.cardSoft)
    }
}

private struct CFInkPawSeal: View {
    var body: some View {
        ZStack {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(CFColor.textTertiary.opacity(0.48))
                .blur(radius: 0.7)
                .offset(x: 0.8, y: 0.7)

            Image(systemName: "pawprint.fill")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(CFColor.textTertiary.opacity(0.62))
                .scaleEffect(x: 0.97, y: 1.03)

            Image(systemName: "pawprint.fill")
                .font(.system(size: 39, weight: .regular))
                .foregroundStyle(CFColor.textTertiary.opacity(0.12))
                .offset(x: -1.2, y: -0.6)
                .blur(radius: 0.35)
        }
        .compositingGroup()
    }
}

private struct OnboardingBubbleShape: Shape {
    var direction: OnboardingBubbleDirection

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = CFRadius.card
        let tailLength: CGFloat = 12
        let tailWidth: CGFloat = 18

        switch direction {
        case .bottom:
            let bubbleBottom = rect.maxY - tailLength
            let tailLeft = rect.midX - tailWidth / 2
            let tailRight = rect.midX + tailWidth / 2

            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: bubbleBottom - radius))
            path.addArc(
                center: CGPoint(x: rect.maxX - radius, y: bubbleBottom - radius),
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: tailRight, y: bubbleBottom))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: tailLeft, y: bubbleBottom))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: bubbleBottom))
            path.addArc(
                center: CGPoint(x: rect.minX + radius, y: bubbleBottom - radius),
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(
                center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        case .leading:
            let bubbleLeft = rect.minX + tailLength
            let tailTop = rect.midY - tailWidth / 2
            let tailBottom = rect.midY + tailWidth / 2

            path.move(to: CGPoint(x: bubbleLeft + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(
                center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: bubbleLeft + radius, y: rect.maxY))
            path.addArc(
                center: CGPoint(x: bubbleLeft + radius, y: rect.maxY - radius),
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: bubbleLeft, y: tailBottom))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: bubbleLeft, y: tailTop))
            path.addLine(to: CGPoint(x: bubbleLeft, y: rect.minY + radius))
            path.addArc(
                center: CGPoint(x: bubbleLeft + radius, y: rect.minY + radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }
        path.closeSubpath()
        return path
    }
}

#Preview("Onboarding") {
    OnboardingFlowView {}
}
