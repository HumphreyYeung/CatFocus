import SwiftUI

struct MyCatView: View {
    var recipientName: String = "Human Friend"
    var postcardProgress = PostcardProgressV1()
    var hasPremiumAccess: Bool = false
    var onTrialRequested: () -> Void = {}
    var onPostcardRead: (String) -> Void = { _ in }
    var onTabSelected: (CFAppTab) -> Void = { _ in }
    var focusedPosterID: String? = nil
    var onPosterFocused: (PostcardDefinition, CGRect, Double) -> Void = { _, _, _ in }
    var onPosterFrameChanged: (String, CGRect) -> Void = { _, _ in }
    @State private var posterFrames: [String: CGRect] = [:]
    @State private var selectedPostcard: PostcardDefinition?
    @State private var isSampleLetterOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
                .padding(.top, CFTabScreenLayout.headerTopPadding)
                .padding(.bottom, CFTabScreenLayout.headerBottomPadding)
                .cfEntrance(offset: -4)

            collectionContent
                .id(collectionState)
                .transition(.opacity.combined(with: .offset(y: 6)))
        }
        .background(CFColor.backgroundPrimary)
        .animation(reduceMotion ? nil : CFMotionCurve.componentTransition, value: collectionState)
    }

    private var header: some View {
        HStack {
            Text("Collection")
                .font(CFFont.screenTitle)
                .foregroundStyle(CFColor.textPrimary)

        }
    }

    @ViewBuilder
    private var collectionContent: some View {
        switch collectionState {
        case .unlock:
            ScrollView(showsIndicators: false) {
                collectionUnlockView
                    .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
                    .padding(.bottom, CFTabScreenLayout.scrollBottomPadding)
            }
        case .none:
            collectionNoneView
        case .layout:
            ScrollView(showsIndicators: false) {
                collectionLayoutView
                    .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
                    .padding(.bottom, CFTabScreenLayout.scrollBottomPadding)
            }
            .scrollDisabled(focusedPosterID != nil)
        }
    }

    private var collectionState: CFCollectionState {
        if !hasPremiumAccess && deliveredPostcards.isEmpty {
            return .unlock
        }
        return deliveredPostcards.isEmpty ? .none : .layout
    }

    private var deliveredPostcards: [PostcardDefinition] {
        postcardProgress.deliveredPostcardIDs
            .reversed()
            .compactMap(PostcardCatalog.definition(id:))
    }

    private var layoutPostcards: [PostcardDefinition] {
        return deliveredPostcards
    }

    private var collectionUnlockView: some View {
        ZStack(alignment: .bottom) {
            Image("CollectionUnlock")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            Button(action: onTrialRequested) {
                Text(CFLocalization.text("Get Pro to Unlock"))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(CFColor.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(CFColor.surfacePrimary)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(CFGradient.spectrumBorder, lineWidth: 1.8)
                    }
                    .cfShadow(CFShadow.cta)
            }
            .buttonStyle(CFPressableStyle())
            .cfBreathingScale()
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
            .accessibilityHint(CFLocalization.text("Opens Pro subscription options"))
        }
        .accessibilityElement(children: .contain)
    }

    private var collectionNoneView: some View {
        VStack(spacing: CFSpacing.xl) {
            Spacer(minLength: 44)

            Image("CollectionArchive")
                .resizable()
                .scaledToFit()
                .frame(width: 116, height: 112)
                .accessibilityHidden(true)

            Text(collectionNoneMessage)
                .font(CFFont.body)
                .foregroundStyle(CFColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: 310)
                .fixedSize(horizontal: false, vertical: true)

            CFPrimaryButton(title: "Start") {
                onTabSelected(.focus)
            }
            .padding(.horizontal, CFButtonLayout.primaryHorizontalInset)
            .padding(.top, CFSpacing.lg)

            Spacer(minLength: 132)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
    }

    private var collectionLayoutView: some View {
        LazyVStack(spacing: CFSpacing.xl) {
            postcardProgressSummary

            ForEach(Array(layoutPostcards.enumerated()), id: \.element.id) { index, postcard in
                Button {
                    guard let sourceFrame = posterFrames[postcard.id] else { return }
                    onPostcardRead(postcard.id)
                    onPosterFocused(
                        postcard,
                        sourceFrame.offsetBy(
                            dx: collectionPosterOffset(at: index),
                            dy: 0
                        ),
                        collectionPosterAngle(at: index)
                    )
                } label: {
                    CFPostcardArtwork.image(baseName: postcard.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .rotationEffect(.degrees(collectionPosterAngle(at: index)))
                        .offset(x: collectionPosterOffset(at: index))
                        .cfShadow(CFShadow.cardSoft)
                        .opacity(
                            focusedPosterID == postcard.id ? 0 : 1
                        )
                        .animation(nil, value: focusedPosterID)
                }
                .buttonStyle(CFCollectionPosterPressStyle())
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: CFCollectionPosterFramePreferenceKey.self,
                            value: [postcard.id: proxy.frame(in: .global)]
                        )
                    }
                }
                .accessibilityLabel("Open \(postcard.localizedTitle)")
            }
        }
        .padding(.top, CFSpacing.xs)
        .onPreferenceChange(CFCollectionPosterFramePreferenceKey.self) { frames in
            posterFrames = frames
            if let focusedPosterID,
               let frame = frames[focusedPosterID],
               let index = layoutPostcards.firstIndex(where: { $0.id == focusedPosterID }) {
                onPosterFrameChanged(
                    focusedPosterID,
                    frame.offsetBy(dx: collectionPosterOffset(at: index), dy: 0)
                )
            }
        }
    }

    private func collectionPosterAngle(at index: Int) -> Double {
        [-2.1, 1.8, -1.2, 1.4][index % 4]
    }

    private func collectionPosterOffset(at index: Int) -> CGFloat {
        [-3, 4, -1, 3][index % 4]
    }

    @ViewBuilder
    private var postcardSection: some View {
        if !catalogIsVisible {
            sampleLetterExperience
        } else {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                CFSectionTitle(title: "Letters from Luna")

                Spacer()

                if catalogIsVisible {
                    Text("\(postcardProgress.activeDayCount) ACTIVE DAYS")
                        .font(CFFont.labelCaps)
                        .tracking(0.8)
                        .foregroundStyle(CFColor.textSecondary)
                }
            }

            if !hasPremiumAccess {
                expiredAccessBanner
            }

            welcomeLetterCard
            postcardProgressSummary

            if let latestUnreadPostcard {
                latestPostcardCard(latestUnreadPostcard)
            }

            LazyVGrid(columns: columns, spacing: CFSpacing.lg) {
                ForEach(PostcardCatalog.all) { postcard in
                    PostcardTile(
                        postcard: postcard,
                        state: state(for: postcard)
                    ) {
                        guard postcardProgress.isDelivered(postcard.id) else { return }
                        selectedPostcard = postcard
                    }
                }
            }
        }
        }
    }

    private var catalogIsVisible: Bool {
        hasPremiumAccess || postcardProgress.hasEverUnlockedCatalog
    }

    private var shouldShowProCTA: Bool {
        !hasPremiumAccess
    }

    private var latestUnreadPostcard: PostcardDefinition? {
        postcardProgress.deliveredPostcardIDs
            .first(where: postcardProgress.isUnread)
            .flatMap(PostcardCatalog.definition(id:))
    }

    private var postcardProgressSummary: some View {
        VStack(alignment: .leading, spacing: CFSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(postcardProgress.deliveredPostcardIDs.count)")
                        .font(CFFont.cardTitle)
                        .foregroundStyle(CFColor.textPrimary)

                    Text("/ \(PostcardCatalog.all.count) COLLECTED")
                        .font(CFFont.labelCaps)
                        .tracking(0.7)
                        .foregroundStyle(CFColor.textSecondary)
                }

                Spacer(minLength: CFSpacing.md)

                Text(CFLocalization.text(postcardProgress.pendingPostcard == nil ? "KEEP GOING" : "ON THE WAY"))
                    .font(CFFont.labelCaps)
                    .tracking(0.7)
                    .foregroundStyle(
                        postcardProgress.pendingPostcard == nil
                            ? CFColor.textTertiary
                            : CFColor.accentTrial
                    )
                    .lineLimit(1)
            }

            Text(nextPostcardText)
                .font(CFFont.bodySmall)
                .foregroundStyle(CFColor.textSecondary)
                .lineLimit(2)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CFColor.divider)

                    Capsule()
                        .fill(
                            postcardProgress.pendingPostcard == nil
                                ? CFColor.textPrimary
                                : CFColor.accentTrial
                        )
                        .frame(width: proxy.size.width * nextMilestoneProgress)
                }
            }
            .frame(height: 3)
            .padding(.top, CFSpacing.xs)
        }
        .padding(.vertical, CFSpacing.sm)
        .accessibilityElement(children: .combine)
    }

    private var nextPostcardText: String {
        if let pendingPostcard = postcardProgress.pendingPostcard {
            return CFLocalization.format("Arrives by %@.", formattedDeliveryDate(pendingPostcard.deliverAt))
        }
        if !postcardProgress.queuedPostcardIDs.isEmpty {
            return CFLocalization.text("Your next letter is queued.")
        }
        if let nextDays = postcardProgress.nextRequiredActiveDays {
            let remaining = max(0, nextDays - postcardProgress.activeDayCount)
            return remaining == 1
                ? CFLocalization.text("1 more active day until the next letter.")
                : CFLocalization.format("%lld more active days until the next letter.", remaining)
        }
        return postcardProgress.deliveredPostcardIDs.count == PostcardCatalog.all.count
            ? CFLocalization.text("Your first album is complete.")
            : CFLocalization.text("Keep showing up. Luna is still exploring.")
    }

    private var collectionNoneMessage: String {
        if let pendingPostcard = postcardProgress.pendingPostcard {
            return CFLocalization.format("Luna is writing. Your first letter arrives by %@.", formattedDeliveryDate(pendingPostcard.deliverAt))
        }
        return CFLocalization.text("Finish a focus session and Luna will start writing your first letter.")
    }

    private func formattedDeliveryDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().locale(CFLocalization.locale))
    }

    private var nextMilestoneProgress: CGFloat {
        guard let nextDays = postcardProgress.nextRequiredActiveDays else { return 1 }
        guard nextDays > 0 else { return 0 }
        return min(1, CGFloat(postcardProgress.activeDayCount) / CGFloat(nextDays))
    }

    private var sampleLetterExperience: some View {
        VStack(alignment: .leading, spacing: CFSpacing.xl) {
            VStack(alignment: .leading, spacing: CFSpacing.sm) {
                HStack(spacing: CFSpacing.sm) {
                    Text("Letters from Luna")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(CFColor.textPrimary)

                    Text("PRO")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(CFColor.textInverse)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(CFSampleLetterStyle.accent)
                        .clipShape(Capsule())
                }

                Text("Keep showing up and Luna will surprise you with photos and handwritten stories from her little adventures.")
                    .font(CFFont.body)
                    .foregroundStyle(CFColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CFSampleLetterPreview(
                recipientName: recipientName,
                isOpen: $isSampleLetterOpen
            )
        }
        .padding(CFSampleLetterStyle.containerPadding)
        .background(CFColor.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: CFSampleLetterStyle.containerCornerRadius, style: .continuous))
    }

    private var proUnlockOverlay: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: CFColor.backgroundPrimary.opacity(0), location: 0),
                    .init(color: CFColor.backgroundPrimary.opacity(0.82), location: 0.43),
                    .init(color: CFColor.backgroundPrimary, location: 0.74)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 232)
            .allowsHitTesting(false)

            CFPrimaryButton(
                title: postcardProgress.hasEverUnlockedCatalog
                    ? "Renew Pro to Keep Receiving"
                    : "Get Pro to Unlock",
                action: onTrialRequested
            )
            .padding(.horizontal, CFButtonLayout.primaryHorizontalInset)
            .padding(.bottom, CFMascotLayout.homePrimaryActionBottomPadding)
            .offset(y: -CFMascotLayout.homeControlsLift)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var expiredAccessBanner: some View {
        Button(action: onTrialRequested) {
            HStack(spacing: CFSpacing.md) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 18, weight: .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text("LETTER DELIVERY PAUSED")
                        .font(CFFont.labelCaps)
                        .tracking(0.7)
                    Text("Your collection is safe. Renew to receive new mail.")
                        .font(CFFont.bodySmall)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(CFColor.textPrimary)
            .padding(CFSpacing.lg)
            .background(CFColor.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityHint("Opens premium access options")
    }

    private var welcomeLetterCard: some View {
        Button {
            selectedPostcard = PostcardCatalog.welcome
        } label: {
            HStack(spacing: CFSpacing.lg) {
                CFPostcardArtwork.image(baseName: PostcardCatalog.welcome.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 64)
                    .padding(5)
                    .background(CFColor.surfacePrimary)
                    .rotationEffect(.degrees(-2))
                    .cfShadow(CFCloudLayer.cardShadow)

                VStack(alignment: .leading, spacing: CFSpacing.xs) {
                    Text("WELCOME LETTER")
                        .font(CFFont.labelCaps)
                        .tracking(1)
                        .foregroundStyle(CFColor.accentSuccess)

                    Text(PostcardCatalog.welcome.localizedTitle)
                        .font(CFFont.cardTitle)
                        .foregroundStyle(CFColor.textPrimary)

                    Text("A promise from Luna, kept forever")
                        .font(CFFont.bodySmall)
                        .foregroundStyle(CFColor.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(CFColor.textTertiary)
            }
            .padding(CFSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CFColor.surfaceWhisper)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .stroke(CFColor.borderSubtle, lineWidth: 0.8)
            }
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel("Welcome letter from Luna")
        .accessibilityHint("Opens Luna's letter")
    }

    private func latestPostcardCard(_ postcard: PostcardDefinition) -> some View {
        Button {
            selectedPostcard = postcard
        } label: {
            HStack(spacing: CFSpacing.lg) {
                CFPostcardArtwork.image(baseName: postcard.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 82, height: 68)
                    .background(CFColor.surfacePrimary)
                    .clipped()
                    .padding(5)
                    .background(CFColor.surfacePrimary)
                    .rotationEffect(.degrees(-2))
                    .cfShadow(CFCloudLayer.cardShadow)

                VStack(alignment: .leading, spacing: 5) {
                    Text("NEW LETTER")
                        .font(CFFont.labelCaps)
                        .tracking(1)
                        .foregroundStyle(CFColor.accentSuccess)
                    Text(postcard.localizedTitle)
                        .font(CFFont.cardTitle)
                        .foregroundStyle(CFColor.textPrimary)
                    Text("Tap to read Luna's note")
                        .font(CFFont.bodySmall)
                        .foregroundStyle(CFColor.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(CFSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CFColor.surfaceWhisper)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .stroke(CFColor.accentSuccess.opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel("New letter, \(postcard.localizedTitle)")
        .accessibilityHint("Opens Luna's letter")
    }

    private func state(for postcard: PostcardDefinition) -> PostcardTileState {
        if postcardProgress.isDelivered(postcard.id) {
            return postcardProgress.isUnread(postcard.id) ? .unread : .collected
        }
        if postcardProgress.pendingPostcard?.postcardID == postcard.id
            || postcardProgress.queuedPostcardIDs.contains(postcard.id) {
            return .onTheWay
        }
        return .locked(requiredDays: postcardProgress.requiredActiveDays(for: postcard))
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: CFSpacing.lg), count: 2)
    }

}

struct CFCollectionPosterFocus: Identifiable {
    var id: String { postcard.id }
    let postcard: PostcardDefinition
    var sourceFrame: CGRect
    let sourceAngle: Double
}

struct CFCollectionPosterFocusOverlay: View {
    let focus: CFCollectionPosterFocus
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false
    @State private var isBackdropVisible = false
    @State private var isGlowVisible = false
    @State private var isCloseVisible = false
    @State private var isDismissing = false
    @State private var returnFrame: CGRect?

    var body: some View {
        GeometryReader { proxy in
            let rootFrame = proxy.frame(in: .global)
            let targetWidth = max(0, proxy.size.width - CFSpacing.xxl)
            let resolvedSourceFrame = returnFrame ?? focus.sourceFrame
            let sourceScale = min(1, resolvedSourceFrame.width / max(targetWidth, 1))
            let sourceOffset = CGSize(
                width: resolvedSourceFrame.midX - rootFrame.midX,
                height: resolvedSourceFrame.midY - rootFrame.midY
            )
            // Keep the close affordance tied to the expanded poster's frame rather
            // than the screen. It stays outside the artwork and never rotates with it.
            let posterRightEdge = proxy.size.width / 2 + targetWidth / 2
            let closeX = min(proxy.size.width - 22, posterRightEdge - 22)
            let closeY = max(
                proxy.safeAreaInsets.top + 28,
                proxy.size.height / 2 - targetWidth * 0.30 - 30
            )

            ZStack {
                Button(action: dismiss) {
                    Color.black.opacity(isBackdropVisible ? 0.78 : 0)
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close poster")

                Ellipse()
                    .fill(accentColor)
                    .frame(
                        width: proxy.size.width * 1.18,
                        height: proxy.size.width * 0.72
                    )
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .blur(radius: 58)
                    .scaleEffect(isGlowVisible ? 1.08 : 0.62)
                    .opacity(isGlowVisible ? 0.46 : 0)
                    .allowsHitTesting(false)

                Ellipse()
                    .fill(Color.white.opacity(0.24))
                    .frame(
                        width: proxy.size.width * 0.82,
                        height: proxy.size.width * 0.48
                    )
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .blur(radius: 44)
                    .scaleEffect(isGlowVisible ? 1 : 0.7)
                    .opacity(isGlowVisible ? 0.36 : 0)
                    .allowsHitTesting(false)

                CFPostcardArtwork.image(baseName: focus.postcard.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: targetWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .scaleEffect(isExpanded ? 1 : sourceScale)
                    .rotationEffect(.degrees(isExpanded || reduceMotion ? 0 : focus.sourceAngle))
                    .rotation3DEffect(
                        .degrees(isExpanded || isDismissing || reduceMotion ? 0 : 11),
                        axis: (x: 0.16, y: 1, z: 0)
                    )
                    .offset(
                        x: isExpanded || reduceMotion ? 0 : sourceOffset.width,
                        y: isExpanded || reduceMotion ? 0 : sourceOffset.height
                    )
                    .shadow(
                        color: .black.opacity(isDismissing ? 0.07 : (isExpanded ? 0.42 : 0.16)),
                        radius: isDismissing ? 8 : (isExpanded ? 30 : 10),
                        y: isDismissing ? 4 : (isExpanded ? 16 : 4)
                    )
                    .accessibilityLabel(focus.postcard.localizedAccessibilityDescription)

                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.46))
                        .clipShape(Circle())
                }
                .buttonStyle(CFPressableStyle())
                .accessibilityLabel("Close poster")
                .scaleEffect(isCloseVisible ? 1 : 0.82)
                .opacity(isCloseVisible ? 1 : 0)
                .position(x: closeX, y: closeY)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onAppear(perform: expand)
    }

    private func expand() {
        if reduceMotion {
            isExpanded = true
            isBackdropVisible = true
            isGlowVisible = true
            isCloseVisible = true
            return
        }

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.14)) {
                isBackdropVisible = true
            }
            withAnimation(
                .interpolatingSpring(
                    mass: 1,
                    stiffness: 360,
                    damping: 32,
                    initialVelocity: 6.2
                )
            ) {
                isExpanded = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            guard !isDismissing else { return }
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.32)) {
                isGlowVisible = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            guard !isDismissing else { return }
            withAnimation(CFMotionCurve.componentTransition) {
                isCloseVisible = true
            }
        }
    }

    private func dismiss() {
        guard !isDismissing else { return }
        // Freeze the destination before the exit begins. Preference updates from
        // the hidden list must not move the target during the final frames.
        returnFrame = focus.sourceFrame
        isDismissing = true

        if reduceMotion {
            onDismiss()
            return
        }

        withAnimation(.easeOut(duration: 0.08)) {
            isGlowVisible = false
            isCloseVisible = false
        }
        withAnimation(
            .timingCurve(0.4, 0, 0.2, 1, duration: 0.22),
            completionCriteria: .removed
        ) {
            isBackdropVisible = false
            isExpanded = false
        } completion: {
            onDismiss()
        }
    }

    private var accentColor: Color {
        switch focus.postcard.imageName {
        case "CollectionPoster01": Color(red: 0.33, green: 0.70, blue: 0.86)
        case "CollectionPoster02": Color(red: 0.95, green: 0.62, blue: 0.30)
        case "CollectionPoster03": Color(red: 0.92, green: 0.49, blue: 0.43)
        case "CollectionPoster04": Color(red: 0.54, green: 0.72, blue: 0.55)
        case "CollectionPoster05": Color(red: 0.54, green: 0.64, blue: 0.84)
        case "CollectionPoster06": Color(red: 0.94, green: 0.72, blue: 0.31)
        case "CollectionPoster07": Color(red: 0.30, green: 0.73, blue: 0.72)
        case "CollectionPoster08": Color(red: 0.93, green: 0.45, blue: 0.36)
        case "CollectionPoster09": Color(red: 0.46, green: 0.72, blue: 0.63)
        case "CollectionPoster10": Color(red: 0.93, green: 0.68, blue: 0.28)
        case "CollectionPoster11": Color(red: 0.38, green: 0.59, blue: 0.82)
        case "CollectionPoster12": Color(red: 0.88, green: 0.38, blue: 0.35)
        default: Color.white.opacity(0.72)
        }
    }
}

struct CFPostcardArrivalOverlay: View {
    let postcard: PostcardDefinition
    let recipientName: String
    let onOpen: () -> Void
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var isFlapOpen = false
    @State private var isPostcardRaised = false
    @State private var isOpening = false
    @State private var isAnticipating = false
    @State private var isEnvelopeReleased = false

    var body: some View {
        ZStack {
            Button(action: onDismiss) {
                Color.black.opacity(isVisible ? 0.92 : 0)
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss new letter")

            VStack(spacing: 18) {
                CFArrivalEnvelope(
                    recipientName: recipientName,
                    postcardImageName: postcard.imageName,
                    isOpen: isFlapOpen,
                    isPostcardRaised: isPostcardRaised
                )
                .frame(width: 286, height: 166)
                .scaleEffect(
                    isAnticipating ? 0.965 : (isEnvelopeReleased ? 1.025 : 1)
                )
                .rotationEffect(
                    .degrees(isAnticipating ? 0.55 : (isEnvelopeReleased ? -0.3 : 0))
                )
                .offset(y: isAnticipating ? 3 : (isEnvelopeReleased ? -2 : 0))

                Button(action: open) {
                    Text("Open letter")
                        .font(CFFont.button)
                        .foregroundStyle(CFColor.textPrimary)
                        .frame(width: 224, height: 50)
                        .background(CFColor.surfacePrimary)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.22), radius: 12, y: 6)
                }
                .buttonStyle(CFPressableStyle())
                .opacity(isOpening ? 0 : 1)
                .scaleEffect(isOpening ? 0.96 : 1)
                .disabled(isOpening)
                .accessibilityHint("Opens Luna's new letter")
            }
            .scaleEffect(isVisible ? 1 : 0.92)
            .opacity(isVisible ? 1 : 0)
            .padding(.horizontal, CFSpacing.xl)
        }
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.32)) {
                    isVisible = true
                }
            }
        }
    }

    private func open() {
        guard !isOpening else { return }
        if reduceMotion {
            onOpen()
            return
        }
        isOpening = true

        withAnimation(.timingCurve(0.32, 0, 0.67, 0, duration: 0.07)) {
            isAnticipating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.23)) {
                isAnticipating = false
                isEnvelopeReleased = true
                isFlapOpen = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation(.timingCurve(0.12, 0.92, 0.2, 1, duration: 0.3)) {
                isPostcardRaised = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.16)) {
                isEnvelopeReleased = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            onOpen()
        }
    }
}

/// A self-contained envelope for the arrival moment. The collection preview
/// has a richer paper composition, while this state should render only the
/// envelope on the veil.
private struct CFArrivalEnvelope: View {
    var recipientName: String
    var postcardImageName: String?
    var isOpen: Bool
    var isPostcardRaised: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let topFlapHeight = size.height * (CGFloat(97) / 151)
            let openSeamOverlap = size.height * (CGFloat(2) / 151)
            // The three SVGs use different canvas sizes. Render the body layers
            // in one 260 x 151 coordinate space, then align their visible strokes
            // instead of their transparent canvas bounds.
            let backVisibleBottom = size.height * (CGFloat(150) / 151)
            let frontVisibleBottom = size.height * (CGFloat(140.229) / 142)
            let frontStrokeAlignment = backVisibleBottom - frontVisibleBottom

            ZStack {
                Image("EnvelopeBack")
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .zIndex(0)

                Image("EnvelopeTopFlap")
                    .resizable()
                    .frame(width: size.width, height: topFlapHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .rotation3DEffect(
                        .degrees(isOpen ? -180 : 0),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .top,
                        perspective: 0.42
                    )
                    .offset(y: isOpen ? openSeamOverlap : 0)
                    .zIndex(isOpen ? 1 : 5)

                if let postcardImageName {
                    CFPostcardArtwork.image(baseName: postcardImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width * 0.91)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .offset(y: isPostcardRaised ? -size.height * 0.48 : 0)
                        .scaleEffect(isPostcardRaised ? 1 : 0.94)
                        .rotationEffect(.degrees(isPostcardRaised ? 0 : -1.4))
                        .opacity(isOpen ? 1 : 0)
                        .zIndex(2)
                }

                Image("EnvelopeFront")
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .offset(y: frontStrokeAlignment)
                .zIndex(3)

                CFEnvelopeAddressLayer(
                    recipientName: recipientName,
                    size: size
                )
                    .opacity(isOpen ? 0 : 1)
                    .zIndex(6)
            }
        }
    }
}

/// Addressing is rendered in the envelope's own coordinate space so it reads
/// like ink on paper instead of a floating modal label.
private struct CFEnvelopeAddressLayer: View {
    let recipientName: String
    let size: CGSize

    private var displayName: String {
        let trimmed = recipientName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? CFLocalization.text("Human Friend") : trimmed
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CFPrintedEnvelopeText(
                    text: CFLocalization.format("TO %@:", displayName),
                    font: .system(size: 12.5, weight: .medium, design: .monospaced),
                    tracking: 0.55
                )

                Spacer(minLength: 0)
            }
            .offset(y: -size.height * 0.17)

            Spacer(minLength: 0)

            HStack {
                Spacer(minLength: 0)

                CFPrintedEnvelopeText(
                    text: CFLocalization.text("FROM LUNA"),
                    font: .system(size: 12.5, weight: .medium, design: .monospaced),
                    tracking: 0.8
                )
            }
            .offset(y: size.height * 0.17)
        }
        .frame(width: size.width * 0.72, height: size.height * 0.56)
        .padding(.vertical, size.height * 0.07)
    }
}

/// Simulates ink absorbed into the paper with a stable base ink layer. Only
/// the ink participates in multiply compositing; the texture is decorative so
/// a device-specific blend-mode difference cannot make the addressing vanish.
private struct CFPrintedEnvelopeText: View {
    let text: String
    let font: Font
    let tracking: CGFloat

    var body: some View {
        ZStack {
            // A soft, low-opacity duplicate simulates ink bleeding into paper.
            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundStyle(Color(red: 0.16, green: 0.15, blue: 0.13).opacity(0.16))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .blur(radius: 0.7)

            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundStyle(Color(red: 0.16, green: 0.15, blue: 0.13).opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .blendMode(.multiply)
                .overlay {
                    Image("LetterPaperTexture")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.34)
                        .mask {
                            Text(text)
                                .font(font)
                                .tracking(tracking)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                }
        }
    }
}

private struct CFCollectionPosterPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(
                .timingCurve(
                    0.2,
                    0,
                    0,
                    1,
                    duration: configuration.isPressed ? 0.08 : 0.11
                ),
                value: configuration.isPressed
            )
    }
}

private struct CFCollectionPosterFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

private enum CFCollectionState: Hashable {
    case unlock
    case none
    case layout
}

private enum CFSampleLetterStyle {
    static let containerPadding: CGFloat = 20
    static let containerCornerRadius: CGFloat = 30
    static let stageHeight: CGFloat = 386
    static let contentInset: CGFloat = 2
    static let letterWidthInset: CGFloat = 22
    static let letterHeight: CGFloat = 292
    static let envelopeHeight: CGFloat = 166
    static let accent = CFColor.accentTrial
    static let paper = Color(red: 0.995, green: 0.982, blue: 0.955)
    static let paperTextureOpacity: CGFloat = 0.22
}

private struct CFSampleLetterPreview: View {
    var recipientName: String
    @Binding var isOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            if reduceMotion {
                isOpen.toggle()
            } else {
                withAnimation(CFMotionCurve.componentTransition) {
                    isOpen.toggle()
                }
            }
        } label: {
            GeometryReader { proxy in
                let envelopeWidth = min(proxy.size.width - CFSampleLetterStyle.contentInset * 2, 302)
                let letterWidth = min(proxy.size.width - CFSampleLetterStyle.letterWidthInset, 278)

                ZStack {
                    letterDecorations

                    sampleLetter
                        .frame(width: letterWidth, height: CFSampleLetterStyle.letterHeight)
                        .offset(y: isOpen ? -42 : 50)
                        .opacity(isOpen ? 1 : 0.08)

                    CFLetterEnvelope(
                        recipientName: displayRecipientName,
                        isOpen: isOpen
                    )
                    .frame(width: envelopeWidth, height: CFSampleLetterStyle.envelopeHeight)
                    .offset(y: isOpen ? 108 : 34)

                    Text(CFLocalization.text(isOpen ? "Tap to close" : "Tap to open Luna's sample letter"))
                        .font(CFFont.caption)
                        .foregroundStyle(CFColor.textSecondary)
                        .padding(.horizontal, CFSpacing.md)
                        .padding(.vertical, CFSpacing.sm)
                        .background(CFColor.surfacePrimary.opacity(0.94))
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, CFSpacing.md)
                }
            }
            .frame(height: CFSampleLetterStyle.stageHeight)
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel(CFLocalization.text(isOpen ? "Sample letter from Luna, partially locked" : "Closed sample letter from Luna"))
        .accessibilityHint(CFLocalization.text(isOpen ? "Closes the sample letter" : "Opens a preview of the Pro letter experience"))
    }

    private var displayRecipientName: String {
        let trimmed = recipientName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? CFLocalization.text("Human Friend") : trimmed
    }

    private var letterDecorations: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(CFSampleLetterStyle.accent.opacity(0.72))
                .frame(width: 74, height: 18)
                .rotationEffect(.degrees(-8))
                .offset(x: -108, y: -158)

            ZStack {
                Circle()
                    .stroke(CFColor.borderSelected, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(width: 66, height: 66)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(CFSampleLetterStyle.accent.opacity(0.78))
            }
            .rotationEffect(.degrees(10))
            .offset(x: 112, y: -150)

            Image(systemName: "pencil.line")
                .font(.system(size: 31, weight: .medium))
                .foregroundStyle(CFColor.textTertiary.opacity(0.55))
                .rotationEffect(.degrees(-26))
                .offset(x: -124, y: 142)
        }
    }

    private var sampleLetter: some View {
        VStack(alignment: .leading, spacing: CFSpacing.sm) {
            HStack {
                Text("SAMPLE LETTER")
                    .font(CFFont.labelCaps)
                    .tracking(1.2)

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundStyle(CFColor.textSecondary)

            CFPostcardArtwork.image(baseName: PostcardCatalog.welcome.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 116)
                .background(CFColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text("Dear \(displayRecipientName),")
                .font(CFFont.pactHandwritten)
                .foregroundStyle(CFColor.textPrimary)

            Text("You keep showing up and I will keep writing. This is our little pact...")
                .font(CFFont.pactHandwrittenSmall)
                .foregroundStyle(CFColor.textPrimary)
                .lineLimit(2)
                .lineSpacing(4)

            Spacer(minLength: 0)

            HStack(spacing: CFSpacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text("THE REST IS FOR PRO FRIENDS")
                        .font(CFFont.labelCaps)
                        .tracking(0.7)
                    Text("Unlock Luna's photos and handwritten stories.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
            }
            .foregroundStyle(CFColor.textPrimary)
            .padding(CFSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CFColor.surfaceSelection)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(CFSpacing.lg)
        .background {
            ZStack {
                CFSampleLetterStyle.paper
                Image("LetterPaperTexture")
                    .resizable()
                    .scaledToFill()
                    .opacity(CFSampleLetterStyle.paperTextureOpacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CFColor.borderPrimary, lineWidth: 1)
        }
        .cfShadow(CFShadow.cardSoft)
    }
}

private struct CFLetterEnvelope: View {
    var recipientName: String
    var headline: String? = nil
    var postcardImageName: String? = nil
    var isOpen: Bool
    var isPostcardRaised: Bool = false
    var showsShadow: Bool = true

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let postcardImageName {
                    CFPostcardArtwork.image(baseName: postcardImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 0.72)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .offset(y: isPostcardRaised ? -proxy.size.height * 0.52 : proxy.size.height * 0.12)
                        .scaleEffect(isPostcardRaised ? 1 : 0.88)
                        .opacity(isPostcardRaised ? 1 : 0)
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                }

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(CFSampleLetterStyle.paper)
                    .overlay {
                        Image("LetterPaperTexture")
                            .resizable()
                            .scaledToFill()
                            .opacity(CFSampleLetterStyle.paperTextureOpacity)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(CFColor.borderPrimary, lineWidth: 1.2)
                    }

                Path { path in
                    path.move(to: CGPoint(x: 1, y: proxy.size.height - 1))
                    path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.48))
                    path.addLine(to: CGPoint(x: proxy.size.width - 1, y: proxy.size.height - 1))
                }
                .stroke(CFColor.borderSelected, lineWidth: 1)

                if headline == nil {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TO")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(1.4)
                            .foregroundStyle(CFColor.textTertiary)
                        Text(recipientName)
                            .font(CFFont.pactHandwritten)
                            .foregroundStyle(CFColor.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, CFSpacing.xl)
                    .offset(y: 14)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(CFColor.borderPrimary, lineWidth: 1)
                        .frame(width: 44, height: 50)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(CFColor.textPrimary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(CFSpacing.lg)

                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 7, y: 7))
                        path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.54))
                        path.addLine(to: CGPoint(x: proxy.size.width - 7, y: 7))
                        path.closeSubpath()
                    }
                    .fill(CFSampleLetterStyle.paper)
                    .overlay {
                        Path { path in
                            path.move(to: CGPoint(x: 7, y: 7))
                            path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.54))
                            path.addLine(to: CGPoint(x: proxy.size.width - 7, y: 7))
                        }
                        .stroke(CFColor.borderSelected, lineWidth: 1)
                    }

                    if let headline {
                        Text(CFLocalization.text(headline))
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(CFColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: proxy.size.width * 0.58)
                            .offset(y: -proxy.size.height * 0.13)
                    }
                }
                .rotation3DEffect(
                    .degrees(isOpen ? -88 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.45
                )
                .opacity(isOpen ? 0 : 1)
            }
            .shadow(
                color: .black.opacity(showsShadow ? 0.07 : 0),
                radius: showsShadow ? 8 : 0,
                y: showsShadow ? 4 : 0
            )
        }
    }
}

private enum PostcardTileState: Equatable {
    case locked(requiredDays: Int)
    case onTheWay
    case unread
    case collected

    var isAvailable: Bool {
        self == .unread || self == .collected
    }
}

private struct PostcardTile: View {
    var postcard: PostcardDefinition
    var state: PostcardTileState
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: CFSpacing.sm) {
                postcardArtwork

                Text(title)
                    .font(CFFont.caption)
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(CFColor.textTertiary)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 174)
            .background(CFColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                    .stroke(state == .unread ? CFColor.accentSuccess : CFColor.borderSubtle, lineWidth: state == .unread ? 1.2 : 0.8)
            }
            .cfShadow(CFCloudLayer.cardShadow)
        }
        .buttonStyle(CFPressableStyle())
        .disabled(!state.isAvailable)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(CFLocalization.text(state.isAvailable ? "Opens the letter" : ""))
    }

    @ViewBuilder
    private var postcardArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(CFColor.surfaceSoft)

            switch state {
            case .collected, .unread:
                CFPostcardArtwork.image(baseName: postcard.imageName)
                    .resizable()
                    .scaledToFill()
                    .clipped()

                if state == .unread {
                    Text("NEW")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(CFColor.textInverse)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(CFColor.accentSuccess)
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(7)
                }
            case .onTheWay:
                VStack(spacing: CFSpacing.xs) {
                    ZStack {
                        Circle()
                            .stroke(
                                CFColor.textTertiary,
                                style: StrokeStyle(lineWidth: 1.2, dash: [3, 3])
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .rotationEffect(.degrees(-8))
                    }
                    Text("ON THE WAY")
                        .font(CFFont.labelCaps)
                        .tracking(0.8)
                }
                .foregroundStyle(CFColor.textSecondary)
            case .locked(let requiredDays):
                VStack(spacing: CFSpacing.sm) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 27, weight: .semibold))
                    Text("\(requiredDays) DAYS")
                        .font(CFFont.labelCaps)
                        .tracking(0.8)
                }
                .foregroundStyle(CFColor.textTertiary)
            }
        }
        .frame(height: 116)
    }

    private var title: String {
        switch state {
        case .collected, .unread: postcard.localizedTitle.uppercased()
        case .onTheWay: CFLocalization.text("A SURPRISE FROM LUNA")
        case .locked: CFLocalization.text("LETTER LOCKED")
        }
    }

    private var subtitle: String {
        switch state {
        case .collected, .unread: postcard.localizedDateLine
        case .onTheWay: CFLocalization.text("Check the mailbox soon")
        case .locked(let requiredDays): CFLocalization.format("Unlocks at %lld active days", requiredDays)
        }
    }

    private var titleColor: Color {
        state == .unread ? CFColor.accentSuccess : CFColor.textPrimary
    }

    private var accessibilityLabel: String {
        switch state {
        case .collected: CFLocalization.format("Collected letter, %@", postcard.localizedTitle)
        case .unread: CFLocalization.format("New letter, %@", postcard.localizedTitle)
        case .onTheWay: CFLocalization.text("Letter from Luna is on the way")
        case .locked(let requiredDays): CFLocalization.format("Locked letter, unlocks at %lld active days", requiredDays)
        }
    }
}

private struct PostcardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var postcard: PostcardDefinition
    var onRead: () -> Void
    @State private var showsLetter = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: CFSpacing.xl) {
                    Button {
                        if reduceMotion {
                            showsLetter.toggle()
                        } else {
                            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                                showsLetter.toggle()
                            }
                        }
                    } label: {
                        Group {
                            if showsLetter {
                                letterSide
                            } else {
                                photoSide
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 430)
                        .rotation3DEffect(
                            reduceMotion ? .zero : .degrees(showsLetter ? 360 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                    }
                    .buttonStyle(CFPressableStyle())
                    .accessibilityLabel(showsLetter ? CFLocalization.text("Letter from Luna") : postcard.localizedAccessibilityDescription)
                    .accessibilityHint("Double tap to turn the letter")

                    Text(CFLocalization.text(showsLetter ? "Tap to see the photo" : "Tap to read Luna's note"))
                        .font(CFFont.bodySmall)
                        .foregroundStyle(CFColor.textSecondary)
                }
                .padding(CFSpacing.xl)
            }
            .background(CFColor.backgroundPrimary)
            .navigationTitle(postcard.localizedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(CFFont.button)
                        .foregroundStyle(CFColor.textPrimary)
                }
            }
        }
        .onAppear(perform: onRead)
    }

    private var photoSide: some View {
        VStack(alignment: .leading, spacing: CFSpacing.md) {
            CFPostcardArtwork.image(baseName: postcard.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(CFColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(postcard.localizedDateLine.uppercased())
                .font(CFFont.labelCaps)
                .tracking(1)
                .foregroundStyle(CFColor.textSecondary)
        }
        .padding(CFSpacing.lg)
        .background(CFColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                .stroke(CFColor.borderSubtle, lineWidth: 0.8)
        }
        .cfShadow(CFShadow.cardSoft)
    }

    private var letterSide: some View {
        VStack(alignment: .leading, spacing: CFSpacing.xl) {
            HStack {
                Text("LETTER FROM LUNA")
                    .font(CFFont.labelCaps)
                    .tracking(1.8)
                Spacer()
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 22, weight: .bold))
            }
            .foregroundStyle(CFColor.textSecondary)

            Divider()

            Text(postcard.localizedLetter)
                .font(CFFont.pactHandwritten)
                .foregroundStyle(CFColor.textPrimary)
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            Text(postcard.localizedDateLine)
                .font(CFFont.caption)
                .foregroundStyle(CFColor.textTertiary)
        }
        .padding(CFSpacing.xl)
        .background(CFColor.surfaceWhisper)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                .stroke(CFColor.borderPrimary, lineWidth: 1)
        }
        .cfShadow(CFShadow.cardSoft)
    }
}

struct CFPremiumLockBadge: View {
    var isVisible: Bool
    var size: CFPremiumLockBadgeSize

    var body: some View {
        Group {
            if isVisible {
                Image(systemName: "lock.fill")
                    .font(.system(size: size.icon, weight: .black))
                    .foregroundStyle(CFColor.textInverse)
                    .frame(width: size.width, height: size.height)
                    .background(CFColor.surfaceSelected)
                    .clipShape(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: size.height / 2,
                                bottomLeading: 0,
                                bottomTrailing: size.bottomTrailingRadius,
                                topTrailing: 0
                            ),
                            style: .continuous
                        )
                    )
            } else {
                Color.clear
                    .frame(width: size.width, height: size.height)
            }
        }
    }
}

enum CFPremiumLockBadgeSize {
    case preset
    case myCat

    var width: CGFloat {
        switch self {
        case .preset: 42
        case .myCat: 48
        }
    }

    var height: CGFloat {
        switch self {
        case .preset: 34
        case .myCat: 40
        }
    }

    var icon: CGFloat {
        switch self {
        case .preset: 9
        case .myCat: 10
        }
    }

    var bottomTrailingRadius: CGFloat {
        switch self {
        case .preset: 13
        case .myCat: 15
        }
    }
}

#Preview("My Cat") {
    MyCatView()
}
