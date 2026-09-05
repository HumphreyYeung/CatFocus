import AVFoundation
import SwiftUI
import UIKit

/// Plays one bundled mascot video inside a fixed canvas and falls back to its poster.
struct CFVideoLoopView: View {
    var videoName: String
    var posterName: String
    var size: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model: CFVideoLoopModel

    init(videoName: String, posterName: String, size: CGSize) {
        self.videoName = videoName
        self.posterName = posterName
        self.size = size
        _model = StateObject(wrappedValue: CFVideoLoopModel(videoName: videoName))
    }

    var body: some View {
        ZStack {
            poster

            if !reduceMotion, let player = model.player {
                CFVideoPlayerView(player: player) {
                    model.markFirstFrameReady()
                }
                .frame(width: size.width, height: size.height)
                .opacity(model.hasRenderedFirstFrame ? 1 : 0)
                // Do not cross-fade the first decoded frame over the poster. A
                // partially decoded frame can otherwise be visible for one
                // render pass and look like a flash/ghost frame on Simulator.
                // The poster remains in place until the player is ready, then
                // the video is revealed atomically.
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .task {
            guard !reduceMotion else { return }
            model.start()
        }
        .onChange(of: reduceMotion) { _, isEnabled in
            if isEnabled {
                model.stop()
            } else {
                model.start()
            }
        }
        .onDisappear {
            model.stop()
        }
        .accessibilityHidden(true)
    }

    private var poster: some View {
        Group {
            if UIImage(named: posterName) != nil {
                Image(posterName)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.white
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

@MainActor
private final class CFVideoLoopModel: ObservableObject {
    @Published private(set) var hasRenderedFirstFrame = false
    @Published private(set) var player: AVPlayer?
    private var statusObservation: NSKeyValueObservation?
    private var endObservation: NSObjectProtocol?
    private var videoName: String

    init(videoName: String) {
        self.videoName = videoName
    }

    func start() {
        guard player == nil else {
            // `start` can be called by both `.task` and the Reduce Motion
            // observer during a view update. Do not let a second call advance
            // the queue before AVPlayerLayer has presented its first frame.
            if hasRenderedFirstFrame {
                player?.play()
            } else {
                player?.pause()
            }
            return
        }

        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            hasRenderedFirstFrame = false
            return
        }

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 0.75
        let videoPlayer = AVPlayer(playerItem: item)
        videoPlayer.actionAtItemEnd = .none
        player = videoPlayer

        // Keep one item mounted for the entire loop. AVPlayerLooper can briefly
        // detach the current item while swapping queue entries, exposing the
        // layer background for one render pass (a white flash in Simulator).
        endObservation = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.hasRenderedFirstFrame else { return }
            self.player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                guard let self, self.hasRenderedFirstFrame else { return }
                self.player?.play()
            }
        }
        statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                if item.status == .failed {
                    self.player?.pause()
                    self.hasRenderedFirstFrame = false
                }
            }
        }
        videoPlayer.pause()
    }

    func markFirstFrameReady() {
        guard !hasRenderedFirstFrame else { return }
        hasRenderedFirstFrame = true
        // Start the clock only after the first frame is ready so the video
        // cannot advance past the poster while its layer is mounting.
        player?.play()
    }

    func stop() {
        player?.pause()
        if let endObservation {
            NotificationCenter.default.removeObserver(endObservation)
        }
        endObservation = nil
        statusObservation?.invalidate()
        statusObservation = nil
        player = nil
        hasRenderedFirstFrame = false
    }
}

private struct CFVideoPlayerView: UIViewRepresentable {
    var player: AVPlayer
    var onReadyForDisplay: () -> Void

    func makeUIView(context: Context) -> CFVideoPlayerContainerView {
        let view = CFVideoPlayerContainerView()
        view.onReadyForDisplay = onReadyForDisplay
        view.player = player
        return view
    }

    func updateUIView(_ uiView: CFVideoPlayerContainerView, context: Context) {
        uiView.onReadyForDisplay = onReadyForDisplay
        uiView.player = player
    }
}

private final class CFVideoPlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var onReadyForDisplay: (() -> Void)?
    private var readyObservation: NSKeyValueObservation?

    var player: AVPlayer? {
        get { (layer as? AVPlayerLayer)?.player }
        set {
            guard let playerLayer = layer as? AVPlayerLayer else { return }
            if playerLayer.player === newValue {
                return
            }
            readyObservation?.invalidate()
            readyObservation = nil
            playerLayer.player = newValue
            playerLayer.videoGravity = .resizeAspect
            playerLayer.isOpaque = true
            playerLayer.backgroundColor = UIColor.white.cgColor
            guard newValue != nil else { return }
            readyObservation = playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] layer, _ in
                guard layer.isReadyForDisplay else { return }
                DispatchQueue.main.async {
                    self?.onReadyForDisplay?()
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        // AVPlayerLayer has implicit Core Animation actions for some layer
        // changes. Suppress them so a layout/rotation update cannot briefly
        // animate the video contents and expose an intermediate frame.
        layer.actions = [
            "contents": NSNull(),
            "bounds": NSNull(),
            "position": NSNull(),
            "opacity": NSNull()
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        readyObservation?.invalidate()
    }
}
