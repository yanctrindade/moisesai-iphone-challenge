import Foundation
@testable import moisesai_iphone_challenge

@MainActor
final class MockAudioPlayerService: AudioPlayerServiceProtocol, @unchecked Sendable {
    var playCallCount = 0
    var pauseCallCount = 0
    var resumeCallCount = 0
    var seekCallCount = 0
    var stopCallCount = 0
    var lastSeekTime: TimeInterval?
    var lastPlayURL: URL?

    var _isPlaying = false
    var _currentTime: TimeInterval = 0
    var _duration: TimeInterval = 30

    private var timeObserver: ((TimeInterval) -> Void)?
    private var endObserver: (() -> Void)?

    var isPlaying: Bool { _isPlaying }
    var currentTime: TimeInterval { _currentTime }
    var duration: TimeInterval { _duration }

    func play(url: URL) {
        playCallCount += 1
        lastPlayURL = url
        _isPlaying = true
    }

    func pause() {
        pauseCallCount += 1
        _isPlaying = false
    }

    func resume() {
        resumeCallCount += 1
        _isPlaying = true
    }

    func seek(to time: TimeInterval) {
        seekCallCount += 1
        lastSeekTime = time
        _currentTime = time
    }

    func stop() {
        stopCallCount += 1
        _isPlaying = false
    }

    func addPeriodicTimeObserver(_ handler: @escaping (TimeInterval) -> Void) {
        timeObserver = handler
    }

    func addPlaybackEndObserver(_ handler: @escaping () -> Void) {
        endObserver = handler
    }

    // Test helpers
    func simulateTimeUpdate(_ time: TimeInterval) {
        _currentTime = time
        timeObserver?(time)
    }

    func simulatePlaybackEnd() {
        endObserver?()
    }
}
