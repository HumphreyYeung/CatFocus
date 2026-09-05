import SwiftUI

struct AppFlowView: View {
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
    @State private var isPresetPresented = false
    @State private var isShareCardPresented = false
    @State private var paywallRequest: CFPaywallRequest?
    @State private var selectedPlan: OnboardingPlan = .weekly
    @State private var shouldRestorePresetAfterPaywall = false
    @State private var debugOnboardingRequested = ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_ONBOARDING")
    @State private var debugPretrainRequested = ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_PRETRAIN")
    @State private var debugContractRequested = ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_CONTRACT")

    var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                    debugOnboardingRequested = false
                    debugPretrainRequested = false
                    debugContractRequested = false
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
                    // Settings only reflects entitlement state. The sole
                    // Paywall entry point is Home > Start.
                    route = nil
                    selectedTab = .focus
                }
            } else {
                tabContent
            }
        }
        .id(routeIdentity)
        .transition(.opacity)
        .animation(CFMotionCurve.layoutTransition, value: routeIdentity)
        .animation(CFMotionCurve.componentTransition, value: selectedTab)
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
                    cat: .default,
                    catAsset: .staticImage(
                        name: TrainingPose(rawValue: selectedTrainingPoseID)?.assetName
                            ?? TrainingPose.default.assetName
                    ),
                    focusMinutes: totalFocusMinutes,
                    fitPoints: totalFitPoints,
                    health: currentFitnessScore,
                    onClose: {
                        isShareCardPresented = false
                    }
                )
            }
        }
        .onAppear {
            updateOrientation(for: route)
        }
        .onChange(of: route) { _, newRoute in
            updateOrientation(for: newRoute)
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

    private var routeIdentity: String {
        if shouldShowOnboarding { return "onboarding" }
        guard let route else { return "home-\(selectedTab.rawValue)" }

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
        ) && !ProcessInfo.processInfo.arguments.contains("UITEST_SKIP_ONBOARDING")
    }

    private var trainingRecords: [TrainingSessionRecord] {
        TrainingRecordsStore.load(from: trainingRecordsData)
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
                    cat: .default,
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
                cat: currentCatProfile,
                selectedPoseID: $selectedTrainingPoseID,
                hasPremiumAccess: entitlementStore.hasPremiumAccess,
                onPremiumRequested: { pose in
                    paywallRequest = CFPaywallRequest(source: .premiumPose(pose))
                },
                onTabSelected: { tab in
                    selectedTab = tab
                }
            )
        }
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
