import Testing
@testable import CatFocus

struct CFAnalyticsEventTests {
    @Test func onboardingEventsUseStableNamesAndStepParameter() {
        let started = CFAnalyticsEvent.onboardingStarted
        let step = CFAnalyticsEvent.onboardingStepCompleted(stepName: "goal")
        let completed = CFAnalyticsEvent.onboardingCompleted

        #expect(started.name == "onboarding_started")
        #expect(step.name == "onboarding_step_completed")
        #expect(step.parameters?["step_name"] as? String == "goal")
        #expect(completed.name == "onboarding_completed")
    }

    @Test func focusEventsCaptureFunnelAndDurationWithoutPersonalData() {
        let started = CFAnalyticsEvent.focusSessionStarted(durationMinutes: 25, isFirstSession: true)
        let completed = CFAnalyticsEvent.focusSessionCompleted(
            plannedDurationMinutes: 25,
            actualDurationSeconds: 1_500
        )
        let endedEarly = CFAnalyticsEvent.focusSessionEndedEarly(
            plannedDurationMinutes: 25,
            elapsedSeconds: 420
        )

        #expect(started.name == "focus_session_started")
        #expect(started.parameters?["duration_minutes"] as? Int == 25)
        #expect(started.parameters?["is_first_session"] as? Bool == true)
        #expect(completed.name == "focus_session_completed")
        #expect(completed.parameters?["planned_duration_minutes"] as? Int == 25)
        #expect(completed.parameters?["actual_duration_seconds"] as? Int == 1_500)
        #expect(endedEarly.name == "focus_session_ended_early")
        #expect(endedEarly.parameters?["elapsed_seconds"] as? Int == 420)
    }
}
