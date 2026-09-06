import SwiftUI

enum FocusPresetSection: String, Identifiable {
    case timerConfiguration
    case focusMode
    case trainingPose
    case whiteNoise

    var id: String { rawValue }
}

struct FocusPresetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDurationMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var selectedTrainingPoseID: String
    @Binding var selectedWhiteNoiseID: String
    @Binding var selectedFocusModeID: String
    @Binding var customFocusModeName: String
    var hasPremiumAccess: Bool = false
    var initialSection: FocusPresetSection = .timerConfiguration
    var onPremiumRequested: (TrainingPose) -> Void = { _ in }
    @State private var draftDurationMinutes: Int
    @State private var draftTrainingPoseID: String
    @State private var draftWhiteNoiseID: String
    @State private var selectedFocusMode: PresetFocusMode
    @State private var draftCustomFocusModeName: String
    @State private var selectedShortBreakMinutes: Int
    @State private var selectedLongBreakMinutes: Int
    @State private var previewAudioPlayer = CFWhiteNoisePlayer()
    @State private var isCustomModeEditorPresented = false
    @State private var isPoseListExpanded = false

    private let durations = [15, 25, 45, 60]

    init(
        selectedDurationMinutes: Binding<Int>,
        shortBreakMinutes: Binding<Int>,
        longBreakMinutes: Binding<Int>,
        selectedTrainingPoseID: Binding<String>,
        selectedWhiteNoiseID: Binding<String>,
        selectedFocusModeID: Binding<String>,
        customFocusModeName: Binding<String>,
        hasPremiumAccess: Bool = false,
        initialSection: FocusPresetSection = .timerConfiguration,
        onPremiumRequested: @escaping (TrainingPose) -> Void = { _ in },
    ) {
        _selectedDurationMinutes = selectedDurationMinutes
        _shortBreakMinutes = shortBreakMinutes
        _longBreakMinutes = longBreakMinutes
        _selectedTrainingPoseID = selectedTrainingPoseID
        _selectedWhiteNoiseID = selectedWhiteNoiseID
        _selectedFocusModeID = selectedFocusModeID
        _customFocusModeName = customFocusModeName
        self.hasPremiumAccess = hasPremiumAccess
        self.initialSection = initialSection
        self.onPremiumRequested = onPremiumRequested
        _draftDurationMinutes = State(initialValue: selectedDurationMinutes.wrappedValue)
        _draftTrainingPoseID = State(
            initialValue: TrainingPose(rawValue: selectedTrainingPoseID.wrappedValue)?.rawValue
                ?? TrainingPose.default.rawValue
        )
        _draftWhiteNoiseID = State(
            initialValue: PresetSound(rawValue: selectedWhiteNoiseID.wrappedValue)?.rawValue
                ?? PresetSound.none.rawValue
        )
        _selectedFocusMode = State(
            initialValue: PresetFocusMode(rawValue: selectedFocusModeID.wrappedValue) ?? .focus
        )
        _draftCustomFocusModeName = State(initialValue: customFocusModeName.wrappedValue)
        _selectedShortBreakMinutes = State(initialValue: shortBreakMinutes.wrappedValue)
        _selectedLongBreakMinutes = State(initialValue: longBreakMinutes.wrappedValue)
    }

    var body: some View {
        CFBottomSheetScaffold(actionPlacement: .none, initialScrollID: initialSection.id) {
            header
        } content: {
            VStack(alignment: .leading, spacing: 32) {
                timerSection
                    .id(FocusPresetSection.timerConfiguration.id)
                poseSection
                    .id(FocusPresetSection.trainingPose.id)
                modeSection
                    .id(FocusPresetSection.focusMode.id)
                soundSection
                    .id(FocusPresetSection.whiteNoise.id)
            }
        } bottomAction: {
            EmptyView()
        }
        .onDisappear {
            previewAudioPlayer.stop()
        }
        .sheet(isPresented: $isCustomModeEditorPresented) {
            CFCustomFocusModeEditor(name: $draftCustomFocusModeName) {
                selectedFocusMode = .custom
                selectedFocusModeID = PresetFocusMode.custom.rawValue
                customFocusModeName = draftCustomFocusModeName.trimmingCharacters(in: .whitespacesAndNewlines)
                isCustomModeEditorPresented = false
            }
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Training Preset")
                .font(CFFont.screenTitle)
                .foregroundStyle(CFColor.textPrimary)

            Spacer()

            Button {
                previewAudioPlayer.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(CFColor.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(CFColor.surfaceSoft)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close preset")
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            sectionTitle("Focus Mode")

            LazyVGrid(columns: columns(count: 3, spacing: 12), spacing: 12) {
                ForEach(modeOptions) { option in
                    CFSelectableTile(
                        icon: option.icon,
                        title: option.displayTitle(customName: draftCustomFocusModeName),
                        state: option == selectedFocusMode ? .selected : option.defaultState,
                        size: .medium
                    ) {
                        guard option.isSelectable else {
                            isCustomModeEditorPresented = true
                            return
                        }
                        if option == .custom {
                            isCustomModeEditorPresented = true
                            return
                        }
                        selectedFocusMode = option
                        selectedFocusModeID = option.rawValue
                    }
                }
            }
        }
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            sectionTitle("Timer Configuration")

            VStack(spacing: CFSpacing.md) {
                CFTimeOptionRow(
                    title: "Focus Duration",
                    selection: Binding(
                        get: { draftDurationMinutes },
                        set: {
                            draftDurationMinutes = $0
                            selectedDurationMinutes = $0
                        }
                    ),
                    choices: durations
                )
                CFTimeOptionRow(
                    title: "Short Break",
                    selection: Binding(
                        get: { selectedShortBreakMinutes },
                        set: {
                            selectedShortBreakMinutes = $0
                            shortBreakMinutes = $0
                        }
                    ),
                    choices: [5, 10, 15]
                )
                CFTimeOptionRow(
                    title: "Long Break",
                    selection: Binding(
                        get: { selectedLongBreakMinutes },
                        set: {
                            selectedLongBreakMinutes = $0
                            longBreakMinutes = $0
                        }
                    ),
                    choices: [10, 15, 20]
                )
            }
            .padding(.horizontal, CFSpacing.xl)
            .padding(.vertical, CFSpacing.lg)
            .background(CFColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous)
                    .stroke(CFColor.borderSubtle, lineWidth: 0.8)
            }
            .cfShadow(CFCloudLayer.cardShadow)
        }
    }

    private var poseSection: some View {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            sectionTitle("Training Pose")

            LazyVGrid(columns: columns(count: 3, spacing: 12), spacing: 12) {
                ForEach(visiblePoses) { pose in
                    CFTrainingPoseTile(
                        pose: pose,
                        state: pose.id == draftTrainingPoseID
                            ? .selected
                            : .normal,
                        // Hard Pay gates starting a session, not browsing the
                        // available Poses. Keep the tiles visually unlocked;
                        // tapping a premium Pose still opens the Paywall.
                        isLocked: false
                    ) {
                        // Poses are browseable and selectable in Hard Pay.
                        // The paywall is intentionally reserved for Home > Start.
                        draftTrainingPoseID = pose.id
                        selectedTrainingPoseID = pose.id
                    }
                }
            }

            if !isPoseListExpanded && TrainingPose.allCases.count > collapsedPoseCount {
                Button {
                    withAnimation(CFMotionCurve.componentTransition) {
                        isPoseListExpanded = true
                    }
                } label: {
                    HStack(spacing: CFSpacing.xs) {
                        Text("Show all \(TrainingPose.allCases.count) poses")
                            .font(CFFont.labelCaps)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(CFColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(CFColor.surfaceSoft)
                    .clipShape(Capsule())
                }
                .buttonStyle(CFPressableStyle())
                .accessibilityLabel("Show all training poses")
            }
        }
    }

    private let collapsedPoseCount = 6

    private var visiblePoses: [TrainingPose] {
        guard !isPoseListExpanded else { return TrainingPose.allCases }

        var poses = Array(TrainingPose.allCases.prefix(collapsedPoseCount))
        if let selectedPose = TrainingPose(rawValue: draftTrainingPoseID), !poses.contains(selectedPose) {
            poses.append(selectedPose)
        }
        return poses
    }

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            sectionTitle("Background Sound")

            LazyVGrid(columns: columns(count: 3, spacing: 12), spacing: 12) {
                ForEach(PresetSound.allCases) { sound in
                    CFSelectableTile(
                        icon: sound.icon,
                        title: sound.title,
                        state: sound.id == draftWhiteNoiseID ? .selected : .normal,
                        size: .sound
                    ) {
                        draftWhiteNoiseID = sound.id
                        selectedWhiteNoiseID = sound.id
                        previewAudioPlayer.play(sound: sound)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        CFSectionTitle(title: title)
    }

    private var modeOptions: [PresetFocusMode] {
        let options = PresetFocusMode.allCases.filter { option in
            option != .custom || !draftCustomFocusModeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard options.contains(.custom) else { return options }
        return [.custom] + options.filter { $0 != .custom }
    }

    private func columns(count: Int, spacing: CGFloat) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
}

enum PresetFocusMode: String, CaseIterable, Identifiable {
    case add
    case focus
    case study
    case read
    case work
    case meditation
    case exercise
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .add:
            "Add"
        case .focus:
            "Focus"
        case .study:
            "Study"
        case .read:
            "Read"
        case .work:
            "Work"
        case .meditation:
            "Meditation"
        case .exercise:
            "Exercise"
        case .custom:
            "Custom"
        }
    }

    var icon: CFIcon {
        switch self {
        case .add:
            .plus
        case .focus:
            .focus
        case .study:
            .book
        case .read:
            .book
        case .work:
            .laptop
        case .meditation:
            .moon
        case .exercise:
            .puzzle
        case .custom:
            .focus
        }
    }

    var defaultState: CFTileState {
        self == .add ? .add : .normal
    }

    var isSelectable: Bool {
        self != .add
    }

    func displayTitle(customName: String) -> String {
        guard self == .custom else { return title }
        let trimmedName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? title : trimmedName
    }
}

private struct CFCustomFocusModeEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    var onSave: () -> Void
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: CFSpacing.lg) {
            HStack {
                Text("Custom Focus Mode")
                    .font(CFFont.cardTitle)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .font(CFFont.body)
                .foregroundStyle(CFColor.textSecondary)
                .buttonStyle(.plain)
            }

            VStack(spacing: CFSpacing.md) {
                Image(systemName: CFIcon.focus.systemName)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(CFColor.textPrimary)
                    .frame(width: 52, height: 52)
                    .background(CFColor.surfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous))

                TextField("NAME YOUR MODE", text: $name)
                    .font(CFFont.body)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .padding(.horizontal, CFSpacing.lg)
                    .frame(height: 52)
                    .background(CFColor.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: CFRadius.tile, style: .continuous)
                            .stroke(
                                isNameFocused ? CFColor.surfaceSelected : CFColor.borderSubtle,
                                lineWidth: isNameFocused ? 1.5 : 1
                            )
                    }
                    .onSubmit {
                        saveIfPossible()
                    }
            }

            CFPrimaryButton(title: "Use This Mode", action: saveIfPossible)
                .opacity(trimmedName.isEmpty ? 0.45 : 1)
                .disabled(trimmedName.isEmpty)
        }
        .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
        .padding(.top, CFSpacing.sm)
        .onAppear {
            isNameFocused = true
        }
    }

    private func saveIfPossible() {
        guard !trimmedName.isEmpty else { return }
        name = trimmedName
        onSave()
        dismiss()
    }
}

private struct CFTrainingPoseTile: View {
    var pose: TrainingPose
    var state: CFTileState
    var isLocked: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: CFSpacing.xs) {
                CFCatHero(asset: pose.catAsset, size: .icon)
                    .scaleEffect(1.8)
                    .frame(height: 38)

                Text(pose.title.uppercased())
                    .font(CFFont.labelCaps)
                    .tracking(0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(CFColor.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 94)
            .padding(.horizontal, CFSpacing.sm)
            .background(CFColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous)
                    .stroke(state == .selected ? CFCloudLayer.graphite : CFColor.borderSubtle, lineWidth: state == .selected ? 1.8 : 0.8)
            }
            .cfShadow(state == .selected ? CFCloudLayer.selectionStrongShadow : CFCloudLayer.cardShadow)
            .overlay(alignment: .topLeading) {
                CFPremiumLockBadge(isVisible: isLocked, size: .preset)
            }
        }
        .buttonStyle(CFPressableStyle())
        .accessibilityLabel(pose.title)
        .accessibilityIdentifier("trainingPose.\(pose.id)")
        .accessibilityAddTraits(state == .selected ? .isSelected : [])
    }

}

#Preview("Focus Preset") {
    FocusPresetSheet(
        selectedDurationMinutes: .constant(25),
        shortBreakMinutes: .constant(5),
        longBreakMinutes: .constant(15),
        selectedTrainingPoseID: .constant(TrainingPose.default.rawValue),
        selectedWhiteNoiseID: .constant(PresetSound.none.rawValue),
        selectedFocusModeID: .constant(PresetFocusMode.focus.rawValue),
        customFocusModeName: .constant("")
    )
}
