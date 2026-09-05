import SwiftUI

/// Keeps cat state changes isolated from the page that owns the product state.
struct CFCatTransitionView: View {
    var asset: CFCatAsset
    var size: CFCatAssetSize
    var alignment: CFCatAlignment = .center
    var speech: CFSpeechBubbleConfig?
    var accessibilityStateLabel: String = "Luna"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedAsset: CFCatAsset
    @State private var displayedSpeech: CFSpeechBubbleConfig?
    @State private var displayedAccessibilityStateLabel: String
    @State private var cloudProgress: CGFloat = 0
    @State private var transitionTask: Task<Void, Never>?
    @State private var transitionID = UUID()

    init(
        asset: CFCatAsset,
        size: CFCatAssetSize,
        alignment: CFCatAlignment = .center,
        speech: CFSpeechBubbleConfig? = nil,
        accessibilityStateLabel: String = "Luna"
    ) {
        self.asset = asset
        self.size = size
        self.alignment = alignment
        self.speech = speech
        self.accessibilityStateLabel = accessibilityStateLabel
        _displayedAsset = State(initialValue: asset)
        _displayedSpeech = State(initialValue: speech)
        _displayedAccessibilityStateLabel = State(initialValue: accessibilityStateLabel)
    }

    var body: some View {
        ZStack {
            CFCatScene(
                asset: displayedAsset,
                size: size,
                alignment: alignment,
                speech: displayedSpeech
            )

            if cloudProgress > 0 {
                CFCloudWipe(progress: cloudProgress)
                    .frame(width: size.frame.width, height: size.frame.height)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size.frame.width, height: size.frame.height)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("catMotionPreview")
        .accessibilityLabel("Luna")
        .accessibilityValue(displayedAccessibilityStateLabel)
        .onChange(of: transitionInput) { _, newInput in
            transition(to: newInput)
        }
        .onDisappear {
            transitionTask?.cancel()
        }
    }

    private var transitionInput: CFCatTransitionInput {
        CFCatTransitionInput(
            asset: asset,
            speech: speech,
            accessibilityStateLabel: accessibilityStateLabel
        )
    }

    private func transition(to newInput: CFCatTransitionInput) {
        transitionTask?.cancel()

        guard newInput.asset != displayedAsset else {
            displayedSpeech = newInput.speech
            displayedAccessibilityStateLabel = newInput.accessibilityStateLabel
            return
        }

        let currentTransitionID = UUID()
        transitionID = currentTransitionID

        if reduceMotion {
            displayedAsset = newInput.asset
            displayedSpeech = newInput.speech
            displayedAccessibilityStateLabel = newInput.accessibilityStateLabel
            cloudProgress = 0
            return
        }

        cloudProgress = 0
        withAnimation(CFMotionCurve.mascotTransitionCover) {
            cloudProgress = 0.5
        }

        transitionTask = Task { @MainActor in
            let swapDelay = UInt64(CFMotionDuration.mascotTransitionCover * 1_000_000_000)
            try? await Task.sleep(nanoseconds: swapDelay)

            guard !Task.isCancelled else { return }
            guard transitionID == currentTransitionID else { return }
            displayedAsset = newInput.asset
            displayedSpeech = newInput.speech
            displayedAccessibilityStateLabel = newInput.accessibilityStateLabel

            withAnimation(CFMotionCurve.mascotTransitionReveal) {
                cloudProgress = 1
            }

            let revealDelay = UInt64(CFMotionDuration.mascotTransitionReveal * 1_000_000_000)
            try? await Task.sleep(nanoseconds: revealDelay)

            guard !Task.isCancelled else { return }
            guard transitionID == currentTransitionID else { return }
            cloudProgress = 0
        }
    }
}

private struct CFCatTransitionInput: Equatable {
    var asset: CFCatAsset
    var speech: CFSpeechBubbleConfig?
    var accessibilityStateLabel: String
}

private struct CFCloudWipe: View {
    var progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let cloudWidth = width * 1.24
            let xOffset = width * 1.15 - progress * (width * 1.15 + cloudWidth)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: proxy.size.height * 0.24, style: .continuous)
                    .fill(CFColor.surfaceSelected)
                    .frame(width: cloudWidth, height: proxy.size.height * 0.76)

                HStack(spacing: -22) {
                    Circle()
                        .frame(width: proxy.size.height * 0.44, height: proxy.size.height * 0.44)
                    Circle()
                        .frame(width: proxy.size.height * 0.58, height: proxy.size.height * 0.58)
                    Circle()
                        .frame(width: proxy.size.height * 0.42, height: proxy.size.height * 0.42)
                }
                .foregroundStyle(CFColor.surfaceSelected)
                .frame(width: cloudWidth, alignment: .center)
                .offset(y: -proxy.size.height * 0.40)
            }
            .frame(width: cloudWidth, height: proxy.size.height)
            .offset(x: xOffset)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

#Preview("Cat Transition") {
    CFCatTransitionPreview()
        .padding()
}

private struct CFCatTransitionPreview: View {
    @State private var asset: CFCatAsset = .staticImage(name: "luna-focus")

    var body: some View {
        VStack(spacing: CFSpacing.xl) {
            CFCatTransitionView(
                asset: asset,
                size: .hero,
                accessibilityStateLabel: asset == .staticImage(name: "luna-focus") ? "Idle" : "Training"
            )

            Button("Toggle State") {
                asset = asset == .staticImage(name: "luna-focus")
                    ? .staticImage(name: "luna-training")
                    : .staticImage(name: "luna-focus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
