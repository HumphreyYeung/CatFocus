import SwiftUI

enum TrainingResultState: Equatable, Sendable {
    case success
    case failure

    var title: String {
        switch self {
        case .success:
            "SUCCESS!"
        case .failure:
            "FAILED!"
        }
    }

    var message: String {
        switch self {
        case .success:
            "Luna is feeling the burn. That workout paid off. You're both getting stronger."
        case .failure:
            "Luna got a little discouraged, but you can still restart together."
        }
    }

    func points(durationMinutes: Int = 25) -> FitPoints {
        switch self {
        case .success:
            .trainingSuccess(durationMinutes: durationMinutes)
        case .failure:
            .trainingFailure
        }
    }

    var tone: CFStatusTone {
        switch self {
        case .success:
            .success
        case .failure:
            .danger
        }
    }

    var catAsset: CFCatAsset {
        switch self {
        case .success:
            .staticImage(name: "luna-success")
        case .failure:
            .staticImage(name: "luna-failure")
        }
    }

    var catAssetName: String {
        switch self {
        case .success:
            "luna-success"
        case .failure:
            "luna-failure"
        }
    }
}

struct CFTrainingResultView: View {
    var state: TrainingResultState
    var durationMinutes: Int = 25
    var breakDurationMinutes: Int = 5
    var userName: String = "Human Friend"
    var trainingPose: TrainingPose = .default
    var focusModeTitle: String = "Focus"
    var primaryAction: () -> Void
    var secondaryAction: () -> Void
    var successPrimaryAction: (() -> Void)? = nil
    @State private var isPreparingVideo = false
    @State private var shareVideoError: String?
    @State private var isVideoSaved = false

    var body: some View {
        portraitContent
        .background(CFColor.backgroundPrimary)
        .overlay {
            if state == .success {
                CFConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .alert("Video Saved", isPresented: $isVideoSaved) {
            Button("OK") {}
        } message: {
            Text("Your focus video is now in Photos.")
        }
        .alert("Save Video", isPresented: Binding(
            get: { shareVideoError != nil },
            set: { if !$0 { shareVideoError = nil } }
        )) {
            Button("OK") { shareVideoError = nil }
        } message: {
            Text(shareVideoError ?? "")
        }
        #if DEBUG
        .task {
            guard ProcessInfo.processInfo.arguments.contains("UITEST_AUTO_SHARE_VIDEO") else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            saveShareVideo()
        }
        #endif
    }

    private var portraitContent: some View {
        VStack(spacing: 0) {
            resultHeader

            Spacer(minLength: CFSpacing.lg)

            Text(state.title)
                .font(.system(size: 26, weight: .black, design: .rounded).italic())
                .foregroundStyle(CFColor.textPrimary)
                .cfEntrance(delay: 0.08)

            CFCatHero(asset: state.catAsset, size: .focusMedia)
                .padding(.top, CFSpacing.sm)
                .cfEntrance(offset: 12)

            resultSummary
                .cfEntrance(delay: 0.16)

            Spacer(minLength: CFSpacing.lg)

            resultActions(horizontalInset: CFButtonLayout.primaryHorizontalInset)
                .cfEntrance(delay: 0.24, offset: 12)
        }
    }

    private var resultSummary: some View {
        VStack(spacing: 0) {
            CFStatusPill(icon: .spark, text: "Fit Points \(signedPoints)", tone: state.tone)
            .padding(.top, CFSpacing.md)

            Text(state.message)
                .font(CFFont.body)
                .foregroundStyle(CFColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 280)
                .padding(.top, CFSpacing.sm)
        }
    }

    private func resultActions(horizontalInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            CFPrimaryButton(
                title: state == .success ? "Start \(breakDurationMinutes) Min Break" : "Back to Home",
                icon: state == .success ? .play : nil,
                action: state == .success ? (successPrimaryAction ?? primaryAction) : primaryAction
            )
            .padding(.horizontal, horizontalInset)

            Button(action: secondaryAction) {
                HStack(spacing: CFSpacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text(state == .success ? "BACK TO HOME" : "RESTART")
                        .font(CFFont.labelCaps)
                        .tracking(0.8)
                }
                .foregroundStyle(CFColor.textTertiary)
                .frame(height: 48)
            }
            .buttonStyle(.plain)
            .padding(.top, CFSpacing.md)
            .padding(.bottom, CFSpacing.xxl)
        }
    }

    private var signedPoints: String {
        let points = state.points(durationMinutes: durationMinutes).value
        return points > 0 ? "+\(points)" : "\(points)"
    }

    private var resultHeader: some View {
        HStack {
            Spacer()

            if state == .success {
                if isPreparingVideo {
                    ProgressView()
                        .tint(CFColor.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(CFColor.surfaceSoft)
                        .clipShape(Circle())
                        .accessibilityLabel("Saving focus video")
                } else {
                    CFIconCircleButton(
                        icon: .share,
                        label: "Save focus video",
                        action: saveShareVideo
                    )
                }
            }
        }
        .frame(height: 36)
        .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
        .padding(.top, CFTabScreenLayout.headerTopPadding)
    }

    private func saveShareVideo() {
        guard !isPreparingVideo else { return }
        isPreparingVideo = true

        Task {
            do {
                let url = try await CFShareVideoComposer.compose(
                    source: trainingPose.catAsset,
                    userName: userName,
                    poseTitle: trainingPose.title,
                    focusModeTitle: focusModeTitle,
                    focusMinutes: durationMinutes,
                    points: state.points(durationMinutes: durationMinutes).value
                )
                #if DEBUG
                try? CFShareVideoComposer.retainDebugCopy(url)
                if ProcessInfo.processInfo.arguments.contains("UITEST_SKIP_PHOTOS_SAVE") {
                    try? FileManager.default.removeItem(at: url)
                    await MainActor.run {
                        isPreparingVideo = false
                        isVideoSaved = true
                    }
                    return
                }
                #endif
                try await CFShareVideoComposer.saveToPhotos(url: url)
                try? FileManager.default.removeItem(at: url)
                await MainActor.run {
                    isPreparingVideo = false
                    isVideoSaved = true
                }
            } catch {
                await MainActor.run {
                    isPreparingVideo = false
                    shareVideoError = error.localizedDescription
                }
            }
        }
    }

}

#Preview("Training Result - Success") {
    CFTrainingResultView(state: .success) {} secondaryAction: {}
}

#Preview("Training Result - Failure") {
    CFTrainingResultView(state: .failure) {} secondaryAction: {}
}
