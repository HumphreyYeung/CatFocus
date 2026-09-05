import SwiftUI

struct MyCatView: View {
    var cat: CatProfile = .default
    @Binding var selectedPoseID: String
    var hasPremiumAccess: Bool = false
    var onPremiumRequested: (TrainingPose) -> Void = { _ in }
    var onTabSelected: (CFAppTab) -> Void = { _ in }

    private var poses: [CatPoseOption] {
        TrainingPose.allCases.map { pose in
            CatPoseOption(
                id: pose.id,
                title: pose.title,
                asset: pose.catAsset,
                isPremium: pose.access == .premium && !hasPremiumAccess,
                state: pose.id == selectedPoseID
                    ? .selected
                    : .normal
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
                .padding(.top, CFTabScreenLayout.headerTopPadding)
                .padding(.bottom, CFTabScreenLayout.headerBottomPadding)
                .cfEntrance(offset: -4)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: CFSpacing.xxl) {
                    catProfileCard.cfEntrance(delay: 0.08)
                    poseSection.cfEntrance(delay: 0.16)
                }
                .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
                .padding(.bottom, CFTabScreenLayout.scrollBottomPadding)
            }

        }
        .background(CFColor.backgroundPrimary)
        .overlay(alignment: .bottom) {
            CFBottomTabBar(selectedTab: .myCat, onSelect: onTabSelected, variant: .floating)
        }
    }

    private var header: some View {
        HStack {
            Text("My Cat")
                .font(CFFont.screenTitle)
                .foregroundStyle(CFColor.textPrimary)

            Spacer()
        }
    }

    private var catProfileCard: some View {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            HStack(alignment: .top) {
                Text(cat.name)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(CFColor.textPrimary)

                Spacer()

                CFStatusPill(icon: .heart, text: cat.fitnessScore.healthStatus.displayLabel, tone: .health)
            }

            CFCatHero(asset: healthAsset, size: .medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, CFSpacing.sm)

            HStack {
                Text("Fitness".uppercased())
                    .font(CFFont.labelCaps)
                    .tracking(1.8)
                    .foregroundStyle(CFColor.textSecondary)

                Spacer()

                Text("\(cat.fitnessScore.value)%")
                    .font(CFFont.cardTitle)
                    .foregroundStyle(CFColor.textSecondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CFColor.divider)

                    Capsule()
                        .fill(CFColor.surfaceSelected)
                        .frame(width: proxy.size.width * CGFloat(cat.fitnessScore.value) / 100)
                }
            }
            .frame(height: 8)
        }
        .padding(CFSpacing.xl)
        .background(CFColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous)
                .stroke(CFColor.borderSubtle, lineWidth: 0.8)
        }
        .cfShadow(CFCloudLayer.cardShadow)
    }

    private var poseSection: some View {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            CFSectionTitle(title: "Training Poses")

            LazyVGrid(columns: columns, spacing: CFSpacing.lg) {
                ForEach(poses) { pose in
                    CatPoseTile(pose: pose) {
                        // Pose browsing and selection never opens the paywall.
                        // Hard Pay is enforced only when Home > Start is tapped.
                        selectedPoseID = pose.id
                    }
                }
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: CFSpacing.lg), count: 2)
    }

    private var healthAsset: CFCatAsset {
        let healthState = cat.fitnessScore.catHealthState
        let assetName = UIImage(named: healthState.assetName) != nil
            ? healthState.assetName
            : healthState.fallbackAssetName
        return .staticImage(name: assetName)
    }
}

private struct CatPoseTile: View {
    var pose: CatPoseOption
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                Spacer(minLength: CFSpacing.md)

                CFCatHero(asset: pose.asset, size: .icon)
                    .scaleEffect(2.25)
                    .frame(height: 68)

                Spacer(minLength: CFSpacing.xs)

                Text(pose.title.uppercased())
                    .font(.system(size: 10.5, weight: pose.state == .selected ? .bold : .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(CFColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: CFSpacing.md)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 124)
            .background(CFColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous)
                .stroke(pose.state == .selected ? CFCloudLayer.graphite : CFColor.borderSubtle, lineWidth: pose.state == .selected ? 1.8 : 0.8)
            }
        .cfShadow(pose.state == .selected ? CFCloudLayer.selectionStrongShadow : CFCloudLayer.cardShadow)
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel(pose.title)
    }

}

private struct CatPoseOption: Identifiable {
    let id: String
    var title: String
    var asset: CFCatAsset
    var isPremium: Bool
    var state: CFTileState
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
    MyCatView(selectedPoseID: .constant(TrainingPose.default.rawValue))
}
