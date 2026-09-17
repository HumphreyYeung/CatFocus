import AVFoundation
import Combine
import UIKit

@MainActor
final class CFWhiteNoisePlayer: NSObject, ObservableObject, @preconcurrency AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var requestedSound: PresetSound = .none
    private var requestedMixesWithOthers = true
    private var interruptionObserver: NSObjectProtocol?
    private var mediaServicesResetObserver: NSObjectProtocol?
    private var didEnterBackgroundObserver: NSObjectProtocol?

    override init() {
        super.init()
        let center = NotificationCenter.default
        interruptionObserver = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }
        mediaServicesResetObserver = center.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildRequestedSound()
            }
        }
        didEnterBackgroundObserver = center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reactivateForBackgroundPlayback()
            }
        }
    }

    /// Releases CatFocus's audio session when the app is idle. This also
    /// cleans up a session left active by an interrupted preview or relaunch.
    static func releaseAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Decorative videos may cause AVPlayer to activate the app's audio
            // session internally. Keep the idle category mixable so that this
            // never interrupts audio from Podcasts, Music, or other apps.
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            debugLog("deactivated", session: session)
        } catch {
            debugLog("deactivate failed: \(error.localizedDescription)", session: session)
        }
    }

    func play(sound: PresetSound, mixesWithOthers: Bool = true) {
        requestedSound = sound
        requestedMixesWithOthers = mixesWithOthers
        guard let resource = sound.resource else {
            stop()
            return
        }

        guard let url = Bundle.main.url(forResource: resource.name, withExtension: resource.ext) else {
            assertionFailure("Missing white noise resource: \(resource.name).\(resource.ext)")
            stop()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            let options: AVAudioSession.CategoryOptions = mixesWithOthers ? [.mixWithOthers] : []
            try session.setCategory(.playback, mode: .default, options: options)
            try session.setActive(true)
            Self.debugLog("activated for \(sound.id)", session: session)

            if player?.url != url {
                player = try AVAudioPlayer(contentsOf: url)
                player?.delegate = self
            }
            player?.numberOfLoops = -1
            player?.prepareToPlay()
            guard player?.play() == true else {
                assertionFailure("Unable to start white noise playback")
                return
            }
        } catch {
            assertionFailure("Unable to play white noise: \(error.localizedDescription)")
            stop()
        }
    }

    func stop() {
        requestedSound = .none
        requestedMixesWithOthers = true
        player?.stop()
        player = nil
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        guard requestedSound != .none else { return }
        play(sound: requestedSound, mixesWithOthers: requestedMixesWithOthers)
    }

    func deactivate() {
        Self.releaseAudioSession()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Infinite looping normally prevents this callback. Restarting here is
        // a defensive fallback for audio-session resets at a file boundary.
        guard flag, requestedSound != .none else { return }
        player.currentTime = 0
        player.numberOfLoops = -1
        player.play()
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else { return }

        guard type == .ended else { return }
        let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
        let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
        guard options.contains(.shouldResume), requestedSound != .none else { return }
        play(sound: requestedSound, mixesWithOthers: requestedMixesWithOthers)
    }

    private func rebuildRequestedSound() {
        let sound = requestedSound
        guard sound != .none else { return }
        player = nil
        play(sound: sound, mixesWithOthers: requestedMixesWithOthers)
    }

    /// iOS can reevaluate an app's audio session during the lock transition.
    /// Reassert the playback category before suspension without affecting
    /// idle screens or preset previews (requestedSound is .none there).
    private func reactivateForBackgroundPlayback() {
        guard requestedSound != .none, let player else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            let options: AVAudioSession.CategoryOptions = requestedMixesWithOthers ? [.mixWithOthers] : []
            try session.setCategory(.playback, mode: .default, options: options)
            try session.setActive(true)
            if !player.isPlaying {
                player.numberOfLoops = -1
                player.play()
            }
            Self.debugLog("reasserted for background playback", session: session)
        } catch {
            Self.debugLog("background reassert failed: \(error.localizedDescription)", session: AVAudioSession.sharedInstance())
        }
    }

    private static func debugLog(_ event: String, session: AVAudioSession) {
        #if DEBUG
        print(
            "[CFAudio] \(event) | category=\(session.category.rawValue) " +
            "otherAudio=\(session.isOtherAudioPlaying) " +
            "silencedHint=\(session.secondaryAudioShouldBeSilencedHint)"
        )
        #endif
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        if let mediaServicesResetObserver {
            NotificationCenter.default.removeObserver(mediaServicesResetObserver)
        }
        if let didEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(didEnterBackgroundObserver)
        }
    }
}
