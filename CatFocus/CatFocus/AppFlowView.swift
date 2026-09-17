import SwiftUI

struct AppFlowView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var entitlementStore = CFEntitlementStore()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: CFAppTab = .focus
    @State private var route: AppRoute?
    @AppStorage("focusDurationMinutes") private var selectedDurationMinutes = 25
    @AppStorage("shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("sessionAlertsEnabled") private var sessionAlertsEnabled = true
    @AppStorage("whiteNoiseEnabled") private var whiteNoiseEnabled = true
    @AppStorage("selectedTrainingPoseID") private var selectedTrainingPoseID = TrainingPose.default.rawValue
    @AppStorage("selectedWhiteNoiseID") private var selectedWhiteNoiseID = PresetSound.none.rawValue
    @AppStorage("selectedFocusModeID") private var selectedFocusModeID = PresetFocusMode.focus.rawValue
    @AppStorage("customFocusModeName") private var customFocusModeName = ""
    @AppStorage("onboardingName") private var onboardingName = ""
    @AppStorage("onboardingGoalID") private var onboardingGoalID = ""
    @AppStorage(TrainingRecordsStore.storageKey) private var trainingRecordsData = Data()
    @AppStorage(PostcardProgressStore.storageKey) private var postcardProgressData = Data()
    @State private var isPresetPresented = false
    @State private var isShareCardPresented = false
    @State private var paywallRequest: CFPaywallRequest?
    @State private var selectedPlan: OnboardingPlan = .weekly
    @State private var shouldRestorePresetAfterPaywall = false
    @State private var debugOnboardingRequested = ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_ONBOARDING")
    @State private var debugPretrainRequested = ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_PRETRAIN")
    @State private var debugContractRequested = ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_CONTRACT")
    @State private var debugNotificationsRequested = ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_NOTIFICATIONS")
    @State private var focusedCollectionPoster: CFCollectionPosterFocus?
    @State private var collectionPosterHapticTrigger = 0
    @State private var arrivingPostcard: PostcardDefinition?
    @State private var surfacedPostcardIDs = Set<String>()
    @State private var collectionPosterFrames: [String: CGRect] = [:]
    @State private var shouldPresentPostcardAfterFocus = false

    var body: some View {
        GeometryReader { proxy in
            Group {
                if shouldShowOnboarding {
                    OnboardingFlowView {
                        hasCompletedOnboarding = true
                        debugOnboardingRequested = false
                        debugPretrainRequested = false
                        debugContractRequested = false
                        debugNotificationsRequested = false
                    }
                } else if route == .training {
                TrainingView(
                    selectedDurationMinutes: $selectedDurationMinutes,
                    shortBreakMinutes: $shortBreakMinutes,
                    longBreakMinutes: $longBreakMinutes,
                    selectedTrainingPoseID: $selectedTrainingPoseID,
                    selectedWhiteNoiseID: $selectedWhiteNoiseID,
                    whiteNoiseEnabled: $whiteNoiseEnabled,
                    sessionAlertsEnabled: $sessionAlertsEnabled,
                    selectedFocusModeID: $selectedFocusModeID,
                    customFocusModeName: $customFocusModeName,
                    healthState: currentCatProfile.fitnessScore.catHealthState,
                    hasPremiumAccess: entitlementStore.hasPremiumAccess,
                    onSuccess: { outcome in
                        handleTrainingOutcome(outcome)
                    },
                    onFailure: { outcome in
                        handleTrainingOutcome(outcome)
                    }
                )
            } else if case .result(let result, _, let poseID, let focusModeTitle) = route {
                TrainingResultScreen(
                    state: result,
                    durationMinutes: resultDurationMinutes,
                    breakDurationMinutes: breakDurationForLatestFocus,
                    userName: displayName,
                    trainingPose: TrainingPose(rawValue: poseID) ?? .default,
                    focusModeTitle: focusModeTitle,
                    onHome: {
                        route = nil
                        selectedTab = .focus
                    },
                    onRestart: {
                        route = .training
                    },
                    onStartBreak: {
                        route = .break(durationMinutes: breakDurationForLatestFocus)
                    }
                )
            } else if case .break(let durationMinutes) = route {
                BreakView(
                    durationMinutes: durationMinutes,
                    sessionAlertsEnabled: $sessionAlertsEnabled,
                    onComplete: {
                        route = .breakComplete
                    },
                    onSkip: {
                        route = nil
                        selectedTab = .focus
                    }
                )
            } else if route == .breakComplete {
                BreakCompleteView(
                    onStartFocus: {
                        route = .training
                    },
                    onDone: {
                        route = nil
                        selectedTab = .focus
                    }
                )
            } else if route == .settings {
                SettingsView(
                    focusDurationMinutes: $selectedDurationMinutes,
                    shortBreakMinutes: $shortBreakMinutes,
                    longBreakMinutes: $longBreakMinutes,
                    sessionAlertsEnabled: $sessionAlertsEnabled,
                    whiteNoiseEnabled: $whiteNoiseEnabled,
                    hasPremiumAccess: entitlementStore.hasPremiumAccess,
                    selectedPlan: entitlementStore.selectedPlan
                ) {
                    route = nil
                } onResetStats: {
                    trainingRecordsData = Data()
                } onPremiumRequested: {
                    paywallRequest = CFPaywallRequest(source: .startTraining)
                }
            } else if arrivingPostcard != nil {
                // Arrival is a focused presentation. Keep the Collection hierarchy
                // out of the render tree so its artwork cannot bleed through the veil.
                Color.black.ignoresSafeArea()
            } else {
                    tabContent
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(alignment: .bottom) {
                if !shouldShowOnboarding && route == nil && focusedCollectionPoster == nil {
                    CFBottomTabBar(
                        selectedTab: selectedTab,
                        onSelect: { tab in
                            selectedTab = tab
                        },
                        variant: .floating
                    )
                }
            }
            .overlay {
                if let arrivingPostcard, focusedCollectionPoster == nil {
                    CFPostcardArrivalOverlay(
                        postcard: arrivingPostcard,
                        recipientName: displayName,
                        onOpen: {
                            openArrivingPostcard(arrivingPostcard)
                        },
                        onDismiss: {
                            self.arrivingPostcard = nil
                        }
                    )
                } else if let focusedCollectionPoster {
                    CFCollectionPosterFocusOverlay(
                        focus: focusedCollectionPoster,
                        onDismiss: {
                            self.focusedCollectionPoster = nil
                        }
                    )
                }
            }
        }
        .id(routeIdentity)
        .transition(.opacity)
        .animation(CFMotionCurve.layoutTransition, value: routeIdentity)
        .animation(CFMotionCurve.componentTransition, value: selectedTab)
        .sensoryFeedback(
            .impact(weight: .light, intensity: 0.78),
            trigger: collectionPosterHapticTrigger
        )
        .sheet(isPresented: $isPresetPresented) {
            FocusPresetSheet(
                selectedDurationMinutes: $selectedDurationMinutes,
                shortBreakMinutes: $shortBreakMinutes,
                longBreakMinutes: $longBreakMinutes,
                selectedTrainingPoseID: $selectedTrainingPoseID,
                selectedWhiteNoiseID: $selectedWhiteNoiseID,
                selectedFocusModeID: $selectedFocusModeID,
                customFocusModeName: $customFocusModeName,
                hasPremiumAccess: entitlementStore.hasPremiumAccess,
                initialSection: .timerConfiguration,
                onPremiumRequested: { pose in
                    shouldRestorePresetAfterPaywall = true
                    isPresetPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        paywallRequest = CFPaywallRequest(source: .premiumPose(pose))
                    }
                }
            )
        }
        .fullScreenCover(item: $paywallRequest, onDismiss: restorePresetIfNeeded) { request in
            CFPaywallScreen(
                selectedPlan: $selectedPlan,
                source: request.source,
                // Keep the Paywall's generic headline when the user skipped
                // entering a name; "Human Friend" is only a display fallback
                // for other parts of the app and should not personalize sales copy.
                userName: onboardingName,
                goalTitle: onboardingGoalTitle,
                onDismiss: { paywallRequest = nil },
                onPurchaseSuccess: {
                    let source = request.source
                    if case .premiumPose(let pose) = source {
                        selectedTrainingPoseID = pose.rawValue
                    }
                    unlockPostcardCatalogIfNeeded()
                    paywallRequest = nil
                    if case .startTraining = source {
                        route = .training
                    }
                }
            )
            .environmentObject(entitlementStore)
        }
        .overlay {
            if isShareCardPresented {
                ShareCardOverlay(
                    catAsset: .staticImage(
                        name: TrainingPose(rawValue: selectedTrainingPoseID)?.assetName
                            ?? TrainingPose.default.assetName
                    ),
                    focusMinutes: totalFocusMinutes,
                    averageFocusMinutes: averageFocusMinutes,
                    focusDays: focusDayCount,
                    sessionCount: completedSessionCount,
                    health: currentFitnessScore,
                    onClose: {
                        isShareCardPresented = false
                    }
                )
            }
        }
        .onAppear {
            updateOrientation(for: route)
            releaseIdleAudioSessionIfNeeded()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("UITEST_RESET_POSTCARDS") {
                postcardProgressData = Data()
            }
            #endif
            synchronizePostcardProgress()
            consumePendingPostcardPresentation()
            presentUnreadPostcardIfAppropriate()
        }
        .onChange(of: route) { _, newRoute in
            updateOrientation(for: newRoute)
            guard newRoute == nil, shouldPresentPostcardAfterFocus else { return }
            shouldPresentPostcardAfterFocus = false
            selectedTab = .myCat
            DispatchQueue.main.async {
                presentUnreadPostcardIfAppropriate()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            releaseIdleAudioSessionIfNeeded()
            synchronizePostcardProgress()
            consumePendingPostcardPresentation()
            presentUnreadPostcardIfAppropriate()
        }
        .onReceive(NotificationCenter.default.publisher(for: CFPostcardNotificationCenter.didTapNotification)) { notification in
            handlePostcardNotification(notification.object as? String)
        }
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_RESULTS") {
                route = .result(.success, durationMinutes: 25, poseID: selectedTrainingPoseID, focusModeTitle: "Focus")
            } else if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_TRAINING") {
                route = .training
            }
        }
        #endif
    }

    private func restorePresetIfNeeded() {
        guard shouldRestorePresetAfterPaywall else { return }

        shouldRestorePresetAfterPaywall = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresetPresented = true
        }
    }

    private func updateOrientation(for route: AppRoute?) {
        CFOrientationCoordinator.shared.setTrainingOrientationEnabled(route == .training)
    }

    private func releaseIdleAudioSessionIfNeeded() {
        guard route == nil, !isPresetPresented else { return }
        CFWhiteNoisePlayer.releaseAudioSession()
    }

    private var routeIdentity: String {
        if shouldShowOnboarding { return "onboarding" }
        guard let route else { return "main-tabs" }

        switch route {
        case .training: return "training"
        case .result(let state, _, _, _): return "result-\(state)"
        case .break(let duration): return "break-\(duration)"
        case .breakComplete: return "break-complete"
        case .settings: return "settings"
        }
    }

    private func startTrainingOrPresentPaywall() {
        guard entitlementStore.hasPremiumAccess else {
            paywallRequest = CFPaywallRequest(source: .startTraining)
            return
        }

        route = .training
    }

    private var shouldShowOnboarding: Bool {
        (
            !hasCompletedOnboarding
                || debugPretrainRequested
                || debugContractRequested
                || debugOnboardingRequested
                || debugNotificationsRequested
        ) && !ProcessInfo.processInfo.arguments.contains("UITEST_SKIP_ONBOARDING")
    }

    private var trainingRecords: [TrainingSessionRecord] {
        TrainingRecordsStore.load(from: trainingRecordsData)
    }

    private var postcardProgress: PostcardProgressV1 {
        PostcardProgressStore.load(from: postcardProgressData)
    }

    private var resultDurationMinutes: Int {
        if case .result(_, let durationMinutes, _, _) = route {
            return durationMinutes
        }
        return selectedDurationMinutes
    }

    private var totalFocusMinutes: Int {
        trainingRecords
            .filter { $0.result == .success }
            .reduce(0) { $0 + $1.focusMinutes }
    }

    private var completedSessionCount: Int {
        trainingRecords.filter { $0.result == .success }.count
    }

    private var focusDayCount: Int {
        let calendar = Calendar.current
        return Set(
            trainingRecords
                .filter { $0.result == .success }
                .map { calendar.startOfDay(for: $0.date) }
        ).count
    }

    private var averageFocusMinutes: Int {
        guard completedSessionCount > 0 else { return 0 }
        return Int((Double(totalFocusMinutes) / Double(completedSessionCount)).rounded())
    }

    private var totalFitPoints: Int {
        trainingRecords.reduce(0) { $0 + $1.fitPoints }
    }

    private var currentFitnessScore: FitnessScore {
        CatHealthCalculator.score(records: trainingRecords)
    }

    private var currentCatProfile: CatProfile {
        CatProfile(
            name: "Luna",
            fitnessScore: currentFitnessScore,
            fitPoints: totalFitPoints
        )
    }

    private var displayName: String {
        let trimmedName = onboardingName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Human Friend" : trimmedName
    }

    private var onboardingGoalTitle: String? {
        switch onboardingGoalID {
        case "work": return "work"
        case "meditation": return "meditation"
        case "reading": return "reading"
        case "study": return "study"
        case "else": return "focus"
        default: return nil
        }
    }

    private var selectedFocusMode: PresetFocusMode {
        PresetFocusMode(rawValue: selectedFocusModeID) ?? .focus
    }

    private var breakDurationForLatestFocus: Int {
        let completedFocusCount = trainingRecords.filter { $0.result == .success }.count
        return completedFocusCount.isMultiple(of: 4) ? longBreakMinutes : shortBreakMinutes
    }

    private func handleTrainingOutcome(_ outcome: TrainingSessionOutcome) {
        let record = TrainingSessionRecord(outcome: outcome)
        trainingRecordsData = TrainingRecordsStore.append(record, to: trainingRecordsData)
        let previousDeliveredPostcardIDs = postcardProgress.deliveredPostcardIDs
        let updatedPostcardProgress = PostcardProgressEngine.record(
            record,
            progress: postcardProgress,
            hasPremiumAccess: entitlementStore.hasPremiumAccess
        )
        persistPostcardProgress(updatedPostcardProgress)
        if outcome.state == .success,
           updatedPostcardProgress.deliveredPostcardIDs != previousDeliveredPostcardIDs {
            shouldPresentPostcardAfterFocus = true
        }
        route = .result(
            outcome.state,
            durationMinutes: outcome.plannedMinutes,
            poseID: selectedTrainingPoseID,
            focusModeTitle: selectedFocusMode.displayTitle(customName: customFocusModeName)
        )
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .focus:
            FocusHomeView(
                state: FocusHomeState(
                    cat: currentCatProfile,
                    selectedDurationMinutes: selectedDurationMinutes
                ),
                onStart: {
                    startTrainingOrPresentPaywall()
                },
                onPreset: {
                    isPresetPresented = true
                },
                onSettings: {
                    route = .settings
                },
                onTabSelected: { tab in
                    selectedTab = tab
                }
            )
        case .stats:
            StatsView(
                cat: currentCatProfile,
                records: trainingRecords,
                onShare: {
                    isShareCardPresented = true
                },
                onTabSelected: { tab in
                selectedTab = tab
                }
            )
        case .myCat:
            MyCatView(
                recipientName: displayName,
                postcardProgress: postcardProgress,
                hasPremiumAccess: entitlementStore.hasPremiumAccess,
                onTrialRequested: {
                    paywallRequest = CFPaywallRequest(source: .myCatPostcards)
                },
                onPostcardRead: { postcardID in
                    let updated = PostcardProgressEngine.markRead(
                        postcardID,
                        progress: postcardProgress
                    )
                    persistPostcardProgress(updated)
                },
                onTabSelected: { tab in
                    selectedTab = tab
                },
                focusedPosterID: focusedCollectionPoster?.id,
                onPosterFocused: { postcard, sourceFrame, sourceAngle in
                    collectionPosterHapticTrigger += 1
                    focusedCollectionPoster = CFCollectionPosterFocus(
                        postcard: postcard,
                        sourceFrame: sourceFrame,
                        sourceAngle: sourceAngle
                    )
                },
                onPosterFrameChanged: { postcardID, frame in
                    collectionPosterFrames[postcardID] = frame
                    guard var focus = focusedCollectionPoster,
                          focus.id == postcardID,
                          focus.sourceFrame != frame else { return }
                    focus.sourceFrame = frame
                    focusedCollectionPoster = focus
                }
            )
        }
    }

    private func synchronizePostcardProgress() {
        let previousProgress = postcardProgress
        let updated = PostcardProgressEngine.prepare(
            progress: postcardProgress,
            existingRecords: trainingRecords,
            hasPremiumAccess: entitlementStore.hasPremiumAccess
        )
        persistPostcardProgress(updated)

        guard updated.deliveredPostcardIDs != previousProgress.deliveredPostcardIDs else { return }
        presentUnreadPostcardIfAppropriate(from: updated)
    }

    private func unlockPostcardCatalogIfNeeded() {
        var updated = postcardProgress
        updated.hasEverUnlockedCatalog = true
        persistPostcardProgress(updated)
    }

    private func persistPostcardProgress(_ updated: PostcardProgressV1) {
        if updated != postcardProgress {
            postcardProgressData = PostcardProgressStore.save(updated)
        }

        Task {
            await CFPostcardNotificationScheduler.schedule(updated.pendingPostcard)
        }
    }

    private func handlePostcardNotification(_ postcardID: String?) {
        synchronizePostcardProgress()
        guard let postcardID else { return }
        UserDefaults.standard.removeObject(forKey: CFPostcardNotificationCenter.pendingPostcardIDKey)
        presentPostcard(PostcardCatalog.definition(id: postcardID))
    }

    private func openArrivingPostcard(_ postcard: PostcardDefinition) {
        let sourceFrame = collectionPosterFrames[postcard.id] ?? {
            let screenBounds = UIScreen.main.bounds
            return CGRect(
                x: screenBounds.midX - 112,
                y: screenBounds.midY - 82,
                width: 224,
                height: 164
            )
        }()
        collectionPosterHapticTrigger += 1
        focusedCollectionPoster = CFCollectionPosterFocus(
            postcard: postcard,
            sourceFrame: sourceFrame,
            sourceAngle: -0.8
        )
        let updated = PostcardProgressEngine.markRead(
            postcard.id,
            progress: postcardProgress
        )
        persistPostcardProgress(updated)
        arrivingPostcard = nil
    }

    private func consumePendingPostcardPresentation() {
        guard let postcardID = UserDefaults.standard.string(
            forKey: CFPostcardNotificationCenter.pendingPostcardIDKey
        ) else { return }
        UserDefaults.standard.removeObject(forKey: CFPostcardNotificationCenter.pendingPostcardIDKey)
        handlePostcardNotification(postcardID)
    }

    private func presentUnreadPostcardIfAppropriate(from progress: PostcardProgressV1? = nil) {
        let currentProgress = progress ?? postcardProgress
        guard arrivingPostcard == nil,
              focusedCollectionPoster == nil,
              paywallRequest == nil,
              route == nil,
              !shouldShowOnboarding else { return }

        guard let postcard = currentProgress.deliveredPostcardIDs
            .compactMap(PostcardCatalog.definition(id:))
            .first(where: {
                !currentProgress.readPostcardIDs.contains($0.id)
                    && !surfacedPostcardIDs.contains($0.id)
            })
        else { return }

        presentPostcard(postcard)
    }

    private func presentPostcard(_ postcard: PostcardDefinition?) {
        guard let postcard,
              arrivingPostcard == nil,
              focusedCollectionPoster == nil else { return }
        surfacedPostcardIDs.insert(postcard.id)
        selectedTab = .myCat
        arrivingPostcard = postcard
    }
}

private enum AppRoute: Equatable {
    case training
    case result(TrainingResultState, durationMinutes: Int, poseID: String, focusModeTitle: String)
    case `break`(durationMinutes: Int)
    case breakComplete
    case settings
}

#Preview("App Flow") {
    AppFlowView()
}
