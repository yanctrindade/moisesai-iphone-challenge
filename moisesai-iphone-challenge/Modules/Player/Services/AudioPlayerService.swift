import AVFoundation
import Combine
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "AudioPlayerService")

@MainActor
protocol AudioPlayerServiceProtocol: AnyObject, Sendable {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }

    func play(url: URL)
    func pause()
    func resume()
    func seek(to time: TimeInterval)
    func stop()

    func addPeriodicTimeObserver(_ handler: @escaping (TimeInterval) -> Void)
    func addPlaybackEndObserver(_ handler: @escaping () -> Void)
}

@MainActor
final class AudioPlayerService: AudioPlayerServiceProtocol, @unchecked Sendable {
    static let shared = AudioPlayerService()

    private init() {}

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var endObserver: NSObjectProtocol?

    var isPlaying: Bool {
        player?.timeControlStatus == .playing
    }

    var currentTime: TimeInterval {
        player?.currentTime().seconds ?? 0
    }

    var duration: TimeInterval {
        player?.currentItem?.duration.seconds ?? 0
    }

    func play(url: URL) {
        stop()

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()

        configureAudioSession()
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }

    func stop() {
        player?.pause()
        removeObservers()
        player = nil
    }

    func addPeriodicTimeObserver(_ handler: @escaping (TimeInterval) -> Void) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            handler(time.seconds)
        }
    }

    func addPlaybackEndObserver(_ handler: @escaping () -> Void) {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            handler()
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    private func removeObservers() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
    }

    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
