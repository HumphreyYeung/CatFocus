import SwiftUI

enum CFCatAsset: Equatable, Sendable {
    case staticImage(name: String)
    case animated(name: String)
    case video(name: String, poster: String)
}

enum CFCatAssetSize: Equatable, Sendable {
    case icon
    case small
    case onboardingCompact
    case medium
    case focusMedia
    case result
    case hero
    case onboardingHero
    case shareCard

    var frame: CGSize {
        switch self {
        case .icon:
            CGSize(width: 28, height: 28)
        case .small:
            CGSize(width: 96, height: 96)
        case .onboardingCompact:
            CGSize(width: 112, height: 112)
        case .medium:
            CGSize(width: 220, height: 220)
        case .focusMedia:
            CGSize(width: 320, height: 320)
        case .result:
            CGSize(width: 320, height: 320)
        case .hero:
            CGSize(width: 320, height: 320)
        case .onboardingHero:
            CGSize(width: 320, height: 320)
        case .shareCard:
            CGSize(width: 260, height: 260)
        }
    }
}

enum CFCatAlignment: Equatable, Sendable {
    case center
    case top
    case bottom
}

enum CFSpeechBubblePlacement: Equatable {
    case topLeading
    case topTrailing

    var alignment: Alignment {
        switch self {
        case .topLeading:
            .topLeading
        case .topTrailing:
            .topTrailing
        }
    }
}

struct CFSpeechBubbleConfig: Equatable {
    var text: String
    var alternateTexts: [String] = []
    var placement: CFSpeechBubblePlacement = .topTrailing
    var offset: CGSize = .zero
    var usesHandwrittenText: Bool = true
    var usesQuietTrainingStyle: Bool = false

    var messages: [String] {
        var seen = Set<String>()
        return ([text] + alternateTexts).filter { seen.insert($0).inserted }
    }
}

struct CFCatScene: View {
    var asset: CFCatAsset
    var size: CFCatAssetSize
    var alignment: CFCatAlignment = .center
    var speech: CFSpeechBubbleConfig?

    var body: some View {
        ZStack(alignment: speech?.placement.alignment ?? .topTrailing) {
            CFCatHero(asset: asset, size: size, alignment: alignment)

            if let speech {
                CFSpeechBubble(
                    messages: speech.messages,
                    usesHandwrittenText: speech.usesHandwrittenText,
                    usesQuietTrainingStyle: speech.usesQuietTrainingStyle
                )
                    .offset(speech.offset)
            }
        }
        .frame(width: size.frame.width, height: size.frame.height, alignment: .center)
        .accessibilityHidden(true)
    }
}

/// Provides the same mascot canvas to Home and Training so resource swaps do not shift the page.
struct CFMascotStage<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(
                width: CFCatAssetSize.focusMedia.frame.width,
                height: CFCatAssetSize.focusMedia.frame.height
            )
            .padding(.top, CFMascotLayout.focusMediaTopPadding)
    }
}

private struct CFSpeechBubble: View {
    var messages: [String]
    var usesHandwrittenText: Bool
    var usesQuietTrainingStyle: Bool

    private static let visibleDuration: UInt64 = 4_000_000_000
    private static let hiddenDuration: UInt64 = 8_000_000_000

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedText = ""
    @State private var isVisible = false
    @State private var messageIndex = 0
    @State private var visibilityTask: Task<Void, Never>?
    @State private var textTransitionTask: Task<Void, Never>?

    var body: some View {
        Text(usesHandwrittenText ? displayedText : displayedText.uppercased())
            .font(usesHandwrittenText ? CFFont.pactHandwrittenSmall : .system(size: 10.5, weight: .semibold, design: .rounded))
            .tracking(0.45)
            .foregroundStyle(
                usesQuietTrainingStyle
                    ? CFColor.textPrimary.opacity(0.68)
                    : CFColor.textInverse
            )
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, usesQuietTrainingStyle ? 4 : 14)
            .frame(minHeight: usesQuietTrainingStyle ? 24 : 34)
            .background {
                if !usesQuietTrainingStyle {
                    Capsule()
                        .fill(CFColor.textPrimary.opacity(0.56))
                        .shadow(color: Color.black.opacity(0.11), radius: 7, x: 0, y: 4)
                }
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 3)
            .scaleEffect(isVisible ? 1 : 0.97)
            .onAppear {
                displayedText = messages.first ?? ""
                isVisible = true
                startVisibilityCycle()
            }
            .onChange(of: messages) { _, newMessages in
                guard let newText = newMessages.first else { return }
                messageIndex = 0
                transition(to: newText, messages: newMessages)
            }
            .onDisappear {
                visibilityTask?.cancel()
                textTransitionTask?.cancel()
            }
    }

    private func transition(to newText: String, messages newMessages: [String]) {
        visibilityTask?.cancel()
        textTransitionTask?.cancel()

        guard newText != displayedText else { return }
        guard !reduceMotion else {
            displayedText = newText
            isVisible = true
            return
        }

        withAnimation(.easeOut(duration: 0.14)) {
            isVisible = false
        }

        textTransitionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }

            displayedText = newText
            withAnimation(.easeIn(duration: 0.22)) {
                isVisible = true
            }

            startVisibilityCycle(messages: newMessages)
        }
    }

    private func startVisibilityCycle(messages cycleMessages: [String] = []) {
        visibilityTask?.cancel()

        guard !reduceMotion else { return }

        visibilityTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.visibleDuration)
                guard !Task.isCancelled else { return }

                withAnimation(.easeOut(duration: 0.20)) {
                    isVisible = false
                }

                try? await Task.sleep(nanoseconds: Self.hiddenDuration)
                guard !Task.isCancelled else { return }

                let availableMessages = cycleMessages.isEmpty ? messages : cycleMessages
                if availableMessages.count > 1 {
                    messageIndex = (messageIndex + 1) % availableMessages.count
                    displayedText = availableMessages[messageIndex]
                }

                withAnimation(.easeIn(duration: 0.24)) {
                    isVisible = true
                }
            }
        }
    }
}

struct CFCatHero: View {
    var asset: CFCatAsset
    var size: CFCatAssetSize
    var alignment: CFCatAlignment = .center

    var body: some View {
        ZStack(alignment: swiftUIAlignment) {
            switch asset {
            case .staticImage(let name), .animated(let name):
                if UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                } else {
                    CFCatFallbackArt()
                }
            case .video(let name, let poster):
                CFVideoLoopView(videoName: name, posterName: poster, size: size.frame)
                    .id(name)
            }
        }
        .frame(width: size.frame.width, height: size.frame.height, alignment: swiftUIAlignment)
        .accessibilityHidden(true)
    }

    private var swiftUIAlignment: Alignment {
        switch alignment {
        case .center:
            .center
        case .top:
            .top
        case .bottom:
            .bottom
        }
    }
}

private struct CFCatFallbackArt: View {
    var body: some View {
        GeometryReader { proxy in
            let base: CGFloat = 220
            let scale = min(proxy.size.width, proxy.size.height) / base

            ZStack {
                Circle()
                    .fill(CFColor.surfaceSelected)
                    .frame(width: 146, height: 146)

                HStack(spacing: 72) {
                    Triangle()
                        .fill(CFColor.surfaceSelected)
                        .frame(width: 36, height: 42)
                        .rotationEffect(.degrees(-18))

                    Triangle()
                        .fill(CFColor.surfaceSelected)
                        .frame(width: 36, height: 42)
                        .rotationEffect(.degrees(18))
                }
                .offset(y: -70)

                HStack(spacing: 28) {
                    Circle()
                        .fill(CFColor.surfacePrimary)
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(CFColor.surfacePrimary)
                        .frame(width: 16, height: 16)
                }
                .offset(y: -22)

                Circle()
                    .fill(CFColor.accentDanger)
                    .frame(width: 10, height: 10)
                    .offset(y: 0)
            }
            .frame(width: base, height: base)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview("Cat Hero") {
    VStack(spacing: CFSpacing.xl) {
        CFCatHero(asset: .staticImage(name: "luna-focus"), size: .hero)
        CFCatHero(asset: .staticImage(name: "luna-icon"), size: .small)
    }
    .padding()
}
