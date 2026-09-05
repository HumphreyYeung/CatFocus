import SwiftUI

struct BreakView: View {
    @Environment(\.scenePhase) private var scenePhase

    let durationMinutes: Int
    @Binding var sessionAlertsEnabled: Bool
    var onComplete: () -> Void
    var onSkip: () -> Void

    @State private var elapsedSeconds: TimeInterval = 0
    @State private var startedAt: Date?
    @State private var timerTask: Task<Void, Never>?
    @State private var didComplete = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CFStatusPill(icon: .moon, text: "Break")
                Spacer()
                CFIconCircleButton(icon: .xmark, label: "End break", action: onSkip)
            }
            .cfEntrance(offset: -4)
            .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
            .padding(.top, CFTabScreenLayout.headerTopPadding)

            Spacer(minLength: CFSpacing.section)

            CFCatHero(
                asset: .video(name: "luna-break", poster: "luna-break-poster"),
                size: .focusMedia
            )
            .padding(.top, CFMascotLayout.focusMediaTopPadding)
            .cfEntrance(delay: 0.08, offset: 12)

            VStack(spacing: CFSpacing.sm) {
                CFAnimatedNumber(value: remainingTimeText)
                    .monospacedDigit()

                Text("TAKE A BREATH")
                    .font(CFFont.caption)
                    .tracking(3)
                    .foregroundStyle(CFColor.textSecondary)
            }
            .padding(.top, CFSpacing.xxl)
            .cfEntrance(delay: 0.16)

            Spacer()

            VStack(spacing: CFSpacing.md) {
                if shouldShowPreviewCompletion {
                    Button("Complete Break Preview", action: completeBreak)
                        .font(CFFont.caption)
                        .foregroundStyle(CFColor.textTertiary)
                }

                CFPrimaryButton(title: "Skip Break", action: onSkip)

                Text("Your next focus starts when you choose it.")
                    .font(CFFont.bodySmall)
                    .foregroundStyle(CFColor.textTertiary)
            }
            .padding(.horizontal, CFButtonLayout.primaryHorizontalInset)
            .padding(.bottom, CFSpacing.xxl)
            .cfEntrance(delay: 0.24, offset: 12)
        }
        .background(CFColor.backgroundPrimary)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            resumeTimer()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            pauseTimer()
        }
        .onChange(of: scenePhase) { _, phase in
            UIApplication.shared.isIdleTimerDisabled = phase == .active
            if phase == .active {
                resumeTimer()
            } else {
                pauseTimer()
            }
        }
    }

    private var totalSeconds: TimeInterval {
        TimeInterval(max(1, durationMinutes) * 60)
    }

    private var remainingTimeText: String {
        let remaining = max(0, Int(ceil(totalSeconds - elapsedSeconds)))
        return String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    private var shouldShowPreviewCompletion: Bool {
        ProcessInfo.processInfo.arguments.contains("UITEST_ENABLE_BREAK_COMPLETION")
    }

    private func resumeTimer() {
        guard !didComplete, timerTask == nil else { return }

        startedAt = Date()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                guard let startedAt else { return }
                elapsedSeconds = min(
                    elapsedSeconds + Date().timeIntervalSince(startedAt),
                    totalSeconds
                )

                if elapsedSeconds >= totalSeconds {
                    completeBreak()
                    return
                }

                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    private func pauseTimer() {
        guard let startedAt else { return }
        elapsedSeconds = min(elapsedSeconds + Date().timeIntervalSince(startedAt), totalSeconds)
        self.startedAt = nil
        timerTask?.cancel()
        timerTask = nil
    }

    private func completeBreak() {
        guard !didComplete else { return }
        didComplete = true
        startedAt = nil
        timerTask?.cancel()
        timerTask = nil

        if sessionAlertsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        onComplete()
    }
}

struct BreakCompleteView: View {
    var onStartFocus: () -> Void
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: CFSpacing.lg)

            CFCatHero(asset: .staticImage(name: "luna-success"), size: .focusMedia)
                .padding(.top, CFMascotLayout.focusMediaTopPadding)

            CFStatusPill(icon: .spark, text: "Break Complete", tone: .success)
                .padding(.top, CFSpacing.lg)

            Text("READY FOR ANOTHER ROUND?")
                .font(.system(size: 25, weight: .black, design: .rounded).italic())
                .foregroundStyle(CFColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, CFSpacing.xl)

            Text("Your next focus session is ready whenever you are.")
                .font(CFFont.body)
                .foregroundStyle(CFColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 270)
                .padding(.top, CFSpacing.md)

            Spacer()

            CFPrimaryButton(title: "Start Next Focus", icon: .play, action: onStartFocus)
                .padding(.horizontal, CFButtonLayout.primaryHorizontalInset)

            Button("DONE", action: onDone)
                .font(CFFont.labelCaps)
                .tracking(1)
                .foregroundStyle(CFColor.textTertiary)
                .frame(height: 48)
                .padding(.bottom, CFSpacing.xxl)
        }
        .background(CFColor.backgroundPrimary)
    }
}

#Preview("Break") {
    BreakView(durationMinutes: 5, sessionAlertsEnabled: .constant(true)) {} onSkip: {}
}
