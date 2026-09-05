import SwiftUI

struct TrainingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @Binding var selectedDurationMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var selectedTrainingPoseID: String
    @Binding var selectedWhiteNoiseID: String
    @Binding var whiteNoiseEnabled: Bool
    @Binding var sessionAlertsEnabled: Bool
    @Binding var selectedFocusModeID: String
    @Binding var customFocusModeName: String
    var healthState: CatHealthState = .sleeping
    var onSuccess: (TrainingSessionOutcome) -> Void
    var onFailure: (TrainingSessionOutcome) -> Void
    var hasPremiumAccess: Bool = false

    @State private var previewAsset: CFCatAsset = .staticImage(name: "luna-focus")
    @State private var sessionDurationMinutes: Int
    @State private var elapsedSeconds: TimeInterval = 0
    @State private var sessionStartedAt: Date?
    @State private var timerTask: Task<Void, Never>?
    @State private var hasStartedSession = false
    @State private var didCompleteSession = false
    @State private var presentedPresetSection: FocusPresetSection?
    @State private var areControlsVisible = true
    @State private var isInteractingWithControl = false
    @State private var controlsVisibilityResetID = UUID()
    @State private var audioPlayer = CFWhiteNoisePlayer()
    @State private var hasEntered = false

    init(
        selectedDurationMinutes: Binding<Int>,
        shortBreakMinutes: Binding<Int>,
        longBreakMinutes: Binding<Int>,
        selectedTrainingPoseID: Binding<String>,
        selectedWhiteNoiseID: Binding<String>,
        whiteNoiseEnabled: Binding<Bool>,
        sessionAlertsEnabled: Binding<Bool>,
        selectedFocusModeID: Binding<String>,
        customFocusModeName: Binding<String>,
        healthState: CatHealthState = .sleeping,
        hasPremiumAccess: Bool = false,
        onSuccess: @escaping (TrainingSessionOutcome) -> Void,
        onFailure: @escaping (TrainingSessionOutcome) -> Void
    ) {
        self._selectedDurationMinutes = selectedDurationMinutes
        self._shortBreakMinutes = shortBreakMinutes
        self._longBreakMinutes = longBreakMinutes
        self._selectedTrainingPoseID = selectedTrainingPoseID
        self._selectedWhiteNoiseID = selectedWhiteNoiseID
        self._whiteNoiseEnabled = whiteNoiseEnabled
        self._sessionAlertsEnabled = sessionAlertsEnabled
        self._selectedFocusModeID = selectedFocusModeID
        self._customFocusModeName = customFocusModeName
        self.healthState = healthState
        self.hasPremiumAccess = hasPremiumAccess
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        _sessionDurationMinutes = State(initialValue: max(1, selectedDurationMinutes.wrappedValue))
        _presentedPresetSection = State(initialValue: nil)
    }

    var body: some View {
        Group {
            GeometryReader { proxy in
                if proxy.size.width > proxy.size.height {
                    landscapeContent
                } else {
                    portraitContent
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                revealControls()
            }
        )
        .background(CFColor.backgroundPrimary)
        .task(id: controlsVisibilityResetID) {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled, presentedPresetSection == nil, !isInteractingWithControl else { return }

            withAnimation(controlsVisibilityAnimation) {
                areControlsVisible = false
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            startSessionIfNeeded()
            startSelectedWhiteNoiseIfNeeded()
            resetControlsVisibilityTimer()
            hasEntered = false
            DispatchQueue.main.async {
                withAnimation(reduceMotion ? .linear(duration: 0.01) : CFMotionCurve.layoutTransition) {
                    hasEntered = true
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            pauseSession()
            audioPlayer.stop()
            audioPlayer.deactivate()
        }
        .onChange(of: scenePhase) { _, phase in
            UIApplication.shared.isIdleTimerDisabled = phase == .active
            if phase == .active {
                resumeSession()
                startSelectedWhiteNoiseIfNeeded()
            } else {
                pauseSession()
                audioPlayer.stop()
                audioPlayer.deactivate()
            }
        }
        .onChange(of: selectedWhiteNoiseID) { _, _ in
            startSelectedWhiteNoiseIfNeeded()
        }
        .onChange(of: whiteNoiseEnabled) { _, _ in
            startSelectedWhiteNoiseIfNeeded()
        }
        .onChange(of: presentedPresetSection) { _, section in
            guard section == nil else { return }
            revealControls()
        }
        .sheet(item: $presentedPresetSection) { section in
            FocusPresetSheet(
                selectedDurationMinutes: $selectedDurationMinutes,
                shortBreakMinutes: $shortBreakMinutes,
                longBreakMinutes: $longBreakMinutes,
                selectedTrainingPoseID: $selectedTrainingPoseID,
                selectedWhiteNoiseID: $selectedWhiteNoiseID,
                selectedFocusModeID: $selectedFocusModeID,
                customFocusModeName: $customFocusModeName,
                hasPremiumAccess: hasPremiumAccess,
                initialSection: section,
            )
        }
    }

    private var portraitContent: some View {
        VStack(spacing: 0) {
            header
                .opacity(areControlsVisible ? 1 : 0)
                .allowsHitTesting(areControlsVisible)
                .accessibilityHidden(!areControlsVisible)

            Color.clear
                .frame(height: CFMascotLayout.topSpacing)

            mascotAndTimer
                .opacity(hasEntered ? 1 : 0)
                .offset(y: hasEntered ? 0 : 10)
                .animation(
                    reduceMotion ? .linear(duration: 0.01) : CFMotionCurve.layoutTransition,
                    value: hasEntered
                )

            Spacer(minLength: CFSpacing.section)

            bottomControls
        }
    }

    private var landscapeContent: some View {
        GeometryReader { proxy in
            ZStack {
                mascotContent
                    .frame(width: CFCatAssetSize.focusMedia.frame.width, height: CFCatAssetSize.focusMedia.frame.height)
                    .offset(
                        x: areControlsVisible ? -min(230, proxy.size.width * 0.23) : 0,
                        y: 34
                    )
                    .opacity(hasEntered ? 1 : 0)
                    .animation(controlsVisibilityAnimation, value: areControlsVisible)

                if areControlsVisible {
                    VStack(spacing: 0) {
                        header

                        Spacer(minLength: CFSpacing.sm)

                        timerReadout

                        Spacer(minLength: CFSpacing.sm)

                        bottomControls
                    }
                    .frame(width: min(390, proxy.size.width * 0.40))
                    .frame(maxHeight: .infinity)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, CFSpacing.sm)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, CFSpacing.sm)
        }
    }

    private var mascotAndTimer: some View {
        VStack(spacing: CFSpacing.xxl) {
            CFMascotStage {
                mascotContent
            }

            timerReadout
        }
    }

    @ViewBuilder
    private var mascotContent: some View {
        if isMotionPreviewEnabled {
            CFCatTransitionView(
                asset: previewAsset,
                size: .focusMedia,
                speech: CFSpeechBubbleConfig(
                    text: CatBubbleCatalog.message(for: CatBubbleContext(
                        pose: selectedTrainingPose,
                        health: healthState,
                        moment: previewAsset == .staticImage(name: "luna-focus") ? .idle : .active
                    )),
                    alternateTexts: CatBubbleCatalog.alternateMessages(for: CatBubbleContext(
                        pose: selectedTrainingPose,
                        health: healthState,
                        moment: previewAsset == .staticImage(name: "luna-focus") ? .idle : .active
                    )),
                    placement: .topTrailing,
                    offset: CGSize(width: 4, height: -8),
                    usesQuietTrainingStyle: true
                ),
                accessibilityStateLabel: previewAsset == .staticImage(name: "luna-focus") ? "Idle" : "Training"
            )
        } else {
            CFCatScene(
                asset: selectedTrainingPose.catAsset,
                size: .focusMedia,
                speech: CFSpeechBubbleConfig(
                    text: CatBubbleCatalog.message(for: CatBubbleContext(
                        pose: selectedTrainingPose,
                        health: healthState,
                        moment: bubbleMoment
                    )),
                    alternateTexts: CatBubbleCatalog.alternateMessages(for: CatBubbleContext(
                        pose: selectedTrainingPose,
                        health: healthState,
                        moment: bubbleMoment
                    )),
                    placement: .topTrailing,
                    offset: CGSize(width: 4, height: -8),
                    usesQuietTrainingStyle: true
                )
            )
        }
    }

    private var timerReadout: some View {
        VStack(spacing: CFSpacing.sm) {
                CFAnimatedNumber(value: remainingTimeText)
                    .monospacedDigit()

            Text("KEEP PUSHING")
                .font(CFFont.caption)
                .tracking(3)
                .foregroundStyle(CFColor.textSecondary)
        }
        .opacity(areControlsVisible ? 1 : 0)
        .accessibilityHidden(!areControlsVisible)
        .animation(controlsVisibilityAnimation, value: areControlsVisible)
    }

    private var bottomControls: some View {
        VStack(spacing: 0) {
            CFSlideToCancel(action: {
                pauseSession()
                onFailure(currentOutcome(state: .failure))
            }, onInteractionChanged: { isInteracting in
                isInteractingWithControl = isInteracting
                if isInteracting {
                    revealControls()
                } else {
                    resetControlsVisibilityTimer()
                }
            })
                .padding(.horizontal, 80)
                .padding(.bottom, CFSpacing.xl)

            if shouldShowPreviewCompletion {
                Button("Complete Preview") {
                    completeSession()
                }
                    .font(CFFont.caption)
                    .foregroundStyle(CFColor.textTertiary)
                    .padding(.bottom, CFSpacing.lg)
            }

            if isMotionPreviewEnabled {
                Button(previewAsset == .staticImage(name: "luna-focus") ? "Preview Training State" : "Preview Idle State") {
                    previewAsset = previewAsset == .staticImage(name: "luna-focus")
                        ? .staticImage(name: "luna-training")
                        : .staticImage(name: "luna-focus")
                }
                .font(CFFont.caption)
                .foregroundStyle(CFColor.textTertiary)
                .accessibilityIdentifier("motionPreviewToggle")
                .padding(.bottom, CFSpacing.lg)
            }
        }
        .opacity(areControlsVisible ? 1 : 0)
        .allowsHitTesting(areControlsVisible)
        .accessibilityHidden(!areControlsVisible)
    }

    private var shouldShowPreviewCompletion: Bool {
        ProcessInfo.processInfo.arguments.contains("UITEST_ENABLE_COMPLETE_PREVIEW")
    }

    private var isMotionPreviewEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("UITEST_ENABLE_MOTION_PREVIEW")
    }

    private var selectedTrainingPose: TrainingPose {
        TrainingPose(rawValue: selectedTrainingPoseID) ?? .default
    }

    private var selectedFocusMode: PresetFocusMode {
        PresetFocusMode(rawValue: selectedFocusModeID) ?? .focus
    }

    private var bubbleMoment: CatBubbleMoment {
        guard hasStartedSession else { return .idle }
        guard isSessionActive else { return .paused }

        let progress = elapsedSeconds / totalSessionSeconds
        switch progress {
        case ..<0.5:
            return .active
        case ..<0.9:
            return .halfway
        default:
            return .almostDone
        }
    }

    private var isSessionActive: Bool {
        sessionStartedAt != nil && !didCompleteSession
    }

    private var totalSessionSeconds: TimeInterval {
        TimeInterval(max(1, sessionDurationMinutes) * 60)
    }

    private var remainingTimeText: String {
        let remainingSeconds = max(0, Int(ceil(totalSessionSeconds - elapsedSeconds)))
        return String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private func startSessionIfNeeded() {
        guard !hasStartedSession else {
            resumeSession()
            return
        }

        hasStartedSession = true
        elapsedSeconds = 0
        resumeSession()
    }

    private func resumeSession() {
        guard !didCompleteSession, timerTask == nil else { return }

        sessionStartedAt = Date()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                guard let sessionStartedAt else { return }

                let currentElapsed = min(
                    elapsedSeconds + Date().timeIntervalSince(sessionStartedAt),
                    totalSessionSeconds
                )
                elapsedSeconds = currentElapsed

                if currentElapsed >= totalSessionSeconds {
                    completeSession()
                    return
                }

                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    private func pauseSession() {
        guard let sessionStartedAt else { return }

        elapsedSeconds = min(
            elapsedSeconds + Date().timeIntervalSince(sessionStartedAt),
            totalSessionSeconds
        )
        self.sessionStartedAt = nil
        timerTask?.cancel()
        timerTask = nil
    }

    private func completeSession() {
        guard !didCompleteSession else { return }

        didCompleteSession = true
        sessionStartedAt = nil
        timerTask?.cancel()
        timerTask = nil
        sendSessionAlert()
        onSuccess(currentOutcome(state: .success))
    }

    private func currentOutcome(state: TrainingResultState) -> TrainingSessionOutcome {
        TrainingSessionOutcome(
            state: state,
            plannedMinutes: sessionDurationMinutes,
            elapsedSeconds: elapsedSeconds
        )
    }

    private func startSelectedWhiteNoiseIfNeeded() {
        guard scenePhase == .active else { return }
        guard whiteNoiseEnabled else {
            audioPlayer.stop()
            return
        }
        audioPlayer.play(sound: PresetSound(rawValue: selectedWhiteNoiseID) ?? .none)
    }

    private func sendSessionAlert() {
        guard sessionAlertsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private var controlsVisibilityAnimation: Animation {
        reduceMotion ? .linear(duration: 0) : CFMotionCurve.trainingControlsVisibility
    }

    private func revealControls() {
        withAnimation(controlsVisibilityAnimation) {
            areControlsVisible = true
        }
        resetControlsVisibilityTimer()
    }

    private func resetControlsVisibilityTimer() {
        controlsVisibilityResetID = UUID()
    }

    private var header: some View {
        HStack {
            Button {
                presentedPresetSection = .focusMode
            } label: {
                CFStatusPill(
                    icon: selectedFocusMode.icon,
                    text: selectedFocusMode.displayTitle(customName: customFocusModeName)
                )
            }
            .buttonStyle(CFPressableStyle())
            .accessibilityIdentifier("trainingFocusModeButton")

            Button {
                presentedPresetSection = .trainingPose
            } label: {
                CFStatusPill(
                    icon: .pose,
                    text: selectedTrainingPose.title
                )
            }
            .buttonStyle(CFPressableStyle())
            .accessibilityLabel("Training pose")
            .accessibilityIdentifier("trainingPoseButton")

            Spacer()
            CFIconCircleButton(icon: .music, label: "White noise") {
                presentedPresetSection = .whiteNoise
            }
        }
        .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
        .padding(.top, CFTabScreenLayout.headerTopPadding)
    }
}

#Preview("Training") {
    TrainingView(
        selectedDurationMinutes: .constant(25),
        shortBreakMinutes: .constant(5),
        longBreakMinutes: .constant(15),
        selectedTrainingPoseID: .constant(TrainingPose.default.rawValue),
        selectedWhiteNoiseID: .constant(PresetSound.none.rawValue),
        whiteNoiseEnabled: .constant(true),
        sessionAlertsEnabled: .constant(true),
        selectedFocusModeID: .constant(PresetFocusMode.focus.rawValue),
        customFocusModeName: .constant("")
    ) { _ in } onFailure: { _ in }
}

private struct CFSlideToCancel: View {
    private let handleWidth: CGFloat = 54
    private let horizontalInset: CGFloat = 14
    private let completionRatio: CGFloat = 0.62

    var action: () -> Void
    var onInteractionChanged: (Bool) -> Void = { _ in }

    @State private var dragOffset: CGFloat = 0
    @State private var didComplete = false

    var body: some View {
        GeometryReader { proxy in
            let travel = max(0, proxy.size.width - handleWidth - (horizontalInset * 2))

            ZStack(alignment: .trailing) {
                Text("SLIDE TO CANCEL")
                    .font(CFFont.labelCaps)
                    .tracking(1.0)
                    .foregroundStyle(CFColor.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .padding(.trailing, handleWidth + CFSpacing.sm)

                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CFColor.textInverse)
                    .frame(width: handleWidth, height: 42)
                    .background(CFColor.surfaceSelected)
                    .clipShape(RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous))
                    .cfShadow(CFShadow.cardSoft)
                    .offset(x: dragOffset)
                    .scaleEffect(abs(dragOffset) >= travel * completionRatio ? 1.04 : 1)
                    .animation(CFMotionCurve.instantFeedback, value: abs(dragOffset) >= travel * completionRatio)
            }
            .padding(.horizontal, horizontalInset)
            .frame(height: 56)
            .background(CFColor.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.button, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: CFRadius.button, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard !didComplete else { return }
                        dragOffset = min(0, max(-travel, value.translation.width))
                    }
                    .onEnded { value in
                        guard !didComplete else { return }

                        let projectedOffset = min(0, max(-travel, value.predictedEndTranslation.width))
                        if abs(projectedOffset) >= travel * completionRatio {
                            didComplete = true
                            withAnimation(CFMotionCurve.interactionFeedback) {
                                dragOffset = -travel
                            }
                            action()
                        } else {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onInteractionChanged(true)
                    }
                    .onEnded { _ in
                        onInteractionChanged(false)
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("slideToCancel")
            .accessibilityLabel("Slide to cancel")
            .accessibilityHint("Swipe left to cancel the training session")
        }
        .frame(height: 56)
    }
}
