import MediaPlayer
import UIKit

/// Shows real training playback on the Lock Screen. Preset previews do not
/// create a Now Playing item.
@MainActor
final class CFNowPlayingController {
    static let shared = CFNowPlayingController()

    private var hasRemoteTargets = false
    private var duration: TimeInterval = 0
    private var onPlay: (() -> Void)?
    private var onPause: (() -> Void)?

    private init() {}

    func start(
        duration: TimeInterval,
        artworkName: String? = nil,
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void
    ) {
        stop()
        self.duration = duration
        self.onPlay = onPlay
        self.onPause = onPause

        let center = MPNowPlayingInfoCenter.default()
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "Focus with Luna",
            MPMediaItemPropertyArtist: "CatFocus • White Noise",
            MPMediaItemPropertyAlbumTitle: "CatFocus",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyIsLiveStream: false
        ]
        let artworkImage = artworkName.flatMap { UIImage(named: $0) }
            ?? UIImage(named: "AppIcon")
        if let artworkImage {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
        }
        center.nowPlayingInfo = info
        center.playbackState = .playing
        UIApplication.shared.beginReceivingRemoteControlEvents()

        let remote = MPRemoteCommandCenter.shared()
        let playToken = remote.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.onPlay?()
                self?.setPlaybackRate(1)
            }
            return .success
        }
        let pauseToken = remote.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.onPause?()
                self?.setPlaybackRate(0)
            }
            return .success
        }
        _ = playToken
        _ = pauseToken
        hasRemoteTargets = true
        remote.playCommand.isEnabled = true
        remote.pauseCommand.isEnabled = true
    }

    func update(elapsed: TimeInterval, isPlaying: Bool) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = min(max(0, elapsed), duration)
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    func setPlaybackRate(_ rate: Float) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = rate > 0 ? .playing : .paused
    }

    func stop() {
        let remote = MPRemoteCommandCenter.shared()
        if hasRemoteTargets {
            remote.playCommand.removeTarget(nil)
            remote.pauseCommand.removeTarget(nil)
            hasRemoteTargets = false
        }
        remote.playCommand.isEnabled = false
        remote.pauseCommand.isEnabled = false
        onPlay = nil
        onPause = nil
        duration = 0
        let center = MPNowPlayingInfoCenter.default()
        center.playbackState = .stopped
        center.nowPlayingInfo = nil
    }
}
