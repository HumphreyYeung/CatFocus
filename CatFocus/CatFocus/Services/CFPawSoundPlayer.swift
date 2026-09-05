import AVFoundation

final class CFPawSoundPlayer {
    private var player: AVAudioPlayer?

    func play() {
        guard let url = Bundle.main.url(forResource: "luna-paw-tap", withExtension: "caf") else {
            assertionFailure("Missing paw sound resource: luna-paw-tap.caf")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.55
            player?.prepareToPlay()
            player?.play()
        } catch {
            assertionFailure("Unable to play paw sound: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    deinit {
        stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
