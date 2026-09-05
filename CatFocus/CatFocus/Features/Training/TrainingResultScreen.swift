import SwiftUI

struct TrainingResultScreen: View {
    var state: TrainingResultState
    var durationMinutes: Int = 25
    var breakDurationMinutes: Int = 5
    var userName: String = "Human Friend"
    var trainingPose: TrainingPose = .default
    var focusModeTitle: String = "Focus"
    var onHome: () -> Void
    var onRestart: () -> Void
    var onStartBreak: () -> Void = {}

    var body: some View {
        CFTrainingResultView(
            state: state,
            durationMinutes: durationMinutes,
            breakDurationMinutes: breakDurationMinutes,
            userName: userName,
            trainingPose: trainingPose,
            focusModeTitle: focusModeTitle,
            primaryAction: onHome,
            secondaryAction: state == .success ? onHome : onRestart,
            successPrimaryAction: onStartBreak
        )
    }
}

#Preview("Training Result Screen") {
    TrainingResultScreen(state: .success, durationMinutes: 25, breakDurationMinutes: 5) {} onRestart: {}
}
