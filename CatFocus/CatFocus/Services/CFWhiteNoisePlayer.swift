import AVFoundation

final class CFWhiteNoisePlayer {
    private var player: AVAudioPlayer?

    func play(sound: PresetSound) {
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
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            if player?.url != url {
                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.prepareToPlay()
            }
            player?.play()
        } catch {
            assertionFailure("Unable to play white noise: \(error.localizedDescription)")
            stop()
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    deinit {
        stop()
        deactivate()
    }
}
