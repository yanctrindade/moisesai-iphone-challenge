import Foundation
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "PlayerViewModel")

@Observable
@MainActor
final class PlayerViewModel {

    // MARK: - ViewState

    enum ViewState {
        case idle
        case playing
        case paused
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case playPause
        case forward
        case backward
        case seekStarted
        case seekChanged(TimeInterval)
        case seekEnded(TimeInterval)
        case toggleRepeat
        case stop
    }

    // MARK: - RepeatMode

    enum RepeatMode {
        case off
        case one
        case all
    }

    // MARK: - Properties

    private(set) var state: ViewState = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var repeatMode: RepeatMode = .off
    private(set) var song: Song
    private(set) var isSeeking = false

    private let playlist: [Song]
    private let audioPlayer: AudioPlayerServiceProtocol
    private let saveRecentlyPlayedUseCase: SaveRecentlyPlayedUseCaseProtocol

    private var currentIndex: Int

    // MARK: - Computed

    var currentTimeFormatted: String {
        formatTime(currentTime)
    }

    var remainingTimeFormatted: String {
        let remaining = max(duration - currentTime, 0)
        return "-\(formatTime(remaining))"
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var hasNext: Bool {
        guard !playlist.isEmpty else { return false }
        return currentIndex < playlist.count - 1 || repeatMode == .all
    }

    var hasPrevious: Bool {
        guard !playlist.isEmpty else { return false }
        return currentIndex > 0 || repeatMode == .all
    }

    // MARK: - Init

    init(
        song: Song,
        playlist: [Song],
        audioPlayer: AudioPlayerServiceProtocol,
        saveRecentlyPlayedUseCase: SaveRecentlyPlayedUseCaseProtocol
    ) {
        self.song = song
        self.playlist = playlist
        self.audioPlayer = audioPlayer
        self.saveRecentlyPlayedUseCase = saveRecentlyPlayedUseCase
        self.currentIndex = playlist.firstIndex(of: song) ?? 0
    }

    // MARK: - Actions

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            startPlayback()
        case .playPause:
            togglePlayPause()
        case .forward:
            skipForward()
        case .backward:
            skipBackward()
        case .seekStarted:
            isSeeking = true
        case .seekChanged(let time):
            currentTime = time
        case .seekEnded(let time):
            currentTime = time
            audioPlayer.seek(to: time)
            // Delay clearing isSeeking so the time observer doesn't
            // snap the slider back to the old position before AVPlayer catches up
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                isSeeking = false
            }
        case .toggleRepeat:
            cycleRepeatMode()
        case .stop:
            audioPlayer.stop()
            state = .idle
        }
    }

    // MARK: - Private

    private func startPlayback() {
        guard let previewURL = song.previewURL else {
            logger.warning("No preview URL for song: \(self.song.trackName)")
            return
        }

        audioPlayer.play(url: previewURL)
        state = .playing
        setupObservers()

        Task {
            await saveRecentlyPlayedUseCase.execute(song)
        }
    }

    private func setupObservers() {
        audioPlayer.addPeriodicTimeObserver { [weak self] time in
            Task { @MainActor in
                guard let self, !self.isSeeking else { return }
                // Only update if change is meaningful to avoid micro-jitter
                if abs(self.currentTime - time) > 0.1 {
                    self.currentTime = time
                }
                let dur = self.audioPlayer.duration
                if dur.isFinite && dur > 0 && self.duration != dur {
                    self.duration = dur
                }
            }
        }

        audioPlayer.addPlaybackEndObserver { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.handlePlaybackEnd()
            }
        }
    }

    private func togglePlayPause() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            state = .paused
        } else {
            audioPlayer.resume()
            state = .playing
        }
    }

    private func skipForward() {
        guard hasNext else { return }

        var nextIndex = currentIndex + 1
        if nextIndex >= playlist.count {
            nextIndex = 0
        }

        navigateToSong(at: nextIndex)
    }

    private func skipBackward() {
        if currentTime > 3 {
            audioPlayer.seek(to: 0)
            currentTime = 0
            return
        }

        guard hasPrevious else { return }

        var prevIndex = currentIndex - 1
        if prevIndex < 0 {
            prevIndex = playlist.count - 1
        }

        navigateToSong(at: prevIndex)
    }

    private func navigateToSong(at index: Int) {
        currentIndex = index
        let nextSong = playlist[index]
        song = nextSong

        guard let previewURL = nextSong.previewURL else { return }

        currentTime = 0
        duration = 0

        audioPlayer.play(url: previewURL)
        state = .playing
        setupObservers()

        Task {
            await saveRecentlyPlayedUseCase.execute(nextSong)
        }
    }

    private func handlePlaybackEnd() {
        switch repeatMode {
        case .one:
            audioPlayer.seek(to: 0)
            audioPlayer.resume()
        case .all:
            skipForward()
        case .off:
            if hasNext {
                skipForward()
            } else {
                state = .paused
                currentTime = 0
            }
        }
    }

    private func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .one
        case .one: repeatMode = .all
        case .all: repeatMode = .off
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
