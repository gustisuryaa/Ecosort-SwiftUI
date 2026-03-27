import AVFoundation
import AudioToolbox

public class SoundManager: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    public static let shared = SoundManager()

    private var bgmPlayer: AVAudioPlayer?
    public private(set) var currentBGMName: String?
    private var sfxPlayers: [AVAudioPlayer] = []

    private override init() {
        super.init()
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        #endif
    }

    //BGM
    public func playBGM(soundName: String, fileExtension: String, fadeDuration: TimeInterval = 1.0) {
        if currentBGMName == soundName { return }

        guard let url = Bundle.main.url(forResource: soundName, withExtension: fileExtension) else { return }

        let oldPlayer = bgmPlayer
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = 0
            newPlayer.prepareToPlay()
            newPlayer.play()

            bgmPlayer = newPlayer
            currentBGMName = soundName
            fadeAudio(player: newPlayer, to: 1.0, duration: fadeDuration)

            if let old = oldPlayer {
                fadeAudio(player: old, to: 0.0, duration: fadeDuration) { old.stop() }
            }
        } catch {}
    }

    public func stopBGM(fadeDuration: TimeInterval = 1.0) {
        guard let player = bgmPlayer else { return }
        currentBGMName = nil
        bgmPlayer = nil

        let fadeSteps    = 20
        let stepDuration = fadeDuration / Double(fadeSteps)
        let volumeStep   = player.volume / Float(fadeSteps)

        for i in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                player.volume -= volumeStep
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
            player.stop()
        }
    }

    //SFX
    public func playSFX(soundName: String, fileExtension: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: fileExtension) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.numberOfLoops = 0
            player.prepareToPlay()
            player.play()
            sfxPlayers.append(player)
        } catch {}
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        sfxPlayers.removeAll { $0 == player }
    }

    public func playSystemSound(correct: Bool) {
        AudioServicesPlaySystemSound(correct ? 1057 : 1053)
    }

    //FADE HELPER
    private func fadeAudio(player: AVAudioPlayer, to targetVolume: Float,
                           duration: TimeInterval, completion: (() -> Void)? = nil) {
        let steps        = 20
        let stepDuration = duration / Double(steps)
        let volumeDelta  = (targetVolume - player.volume) / Float(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                player.volume += volumeDelta
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            player.volume = targetVolume
            completion?()
        }
    }
}
