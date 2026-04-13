import Testing
@testable import moisesai_iphone_challenge

@Suite("PlayerViewModel Tests")
@MainActor
struct PlayerViewModelTests {

    private func makeSUT(
        song: Song? = nil,
        playlist: [Song]? = nil
    ) -> (PlayerViewModel, MockAudioPlayerService, MockSaveRecentlyPlayedUseCase) {
        let audioPlayer = MockAudioPlayerService()
        let saveUseCase = MockSaveRecentlyPlayedUseCase()
        let songs = playlist ?? SongFixture.makeList(count: 5)
        let currentSong = song ?? songs[0]

        let viewModel = PlayerViewModel(
            song: currentSong,
            playlist: songs,
            audioPlayer: audioPlayer,
            saveRecentlyPlayedUseCase: saveUseCase
        )
        return (viewModel, audioPlayer, saveUseCase)
    }

    // MARK: - Initial State

    @Test func test_initialState_isIdle() {
        let (sut, _, _) = makeSUT()
        if case .idle = sut.state {} else {
            Issue.record("Expected idle state")
        }
    }

    @Test func test_initialState_timeIsZero() {
        let (sut, _, _) = makeSUT()
        #expect(sut.currentTime == 0)
        #expect(sut.duration == 0)
    }

    // MARK: - onAppear

    @Test func test_send_onAppear_startsPlayback() async throws {
        let (sut, audioPlayer, _) = makeSUT()

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        #expect(audioPlayer.playCallCount == 1)
        if case .playing = sut.state {} else {
            Issue.record("Expected playing state")
        }
    }

    @Test func test_send_onAppear_savesRecentlyPlayed() async throws {
        let (sut, _, saveUseCase) = makeSUT()

        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(100))

        #expect(saveUseCase.executeCallCount == 1)
    }

    // MARK: - Play/Pause

    @Test func test_send_playPause_whenPlaying_pauses() async throws {
        let (sut, audioPlayer, _) = makeSUT()
        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(50))

        sut.send(.playPause)

        #expect(audioPlayer.pauseCallCount == 1)
        if case .paused = sut.state {} else {
            Issue.record("Expected paused state")
        }
    }

    @Test func test_send_playPause_whenPaused_resumes() async throws {
        let (sut, audioPlayer, _) = makeSUT()
        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(50))
        sut.send(.playPause) // pause

        sut.send(.playPause) // resume

        #expect(audioPlayer.resumeCallCount == 1)
        if case .playing = sut.state {} else {
            Issue.record("Expected playing state")
        }
    }

    // MARK: - Forward/Backward

    @Test func test_send_forward_playsNextSong() async throws {
        let (sut, audioPlayer, _) = makeSUT()
        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(50))

        sut.send(.forward)

        #expect(audioPlayer.playCallCount == 2) // initial + forward
    }

    @Test func test_send_backward_whenEarlyInSong_playsPreviousSong() async throws {
        let songs = SongFixture.makeList(count: 3)
        let (sut, audioPlayer, _) = makeSUT(song: songs[1], playlist: songs)
        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(50))

        sut.send(.backward) // currentTime is 0, so goes to previous

        #expect(audioPlayer.playCallCount == 2)
    }

    @Test func test_send_backward_whenDeepInSong_restartsCurrent() async throws {
        let (sut, audioPlayer, _) = makeSUT()
        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(50))
        audioPlayer.simulateTimeUpdate(5)
        try await Task.sleep(for: .milliseconds(50))

        sut.send(.backward)

        #expect(audioPlayer.seekCallCount == 1)
        #expect(audioPlayer.lastSeekTime == 0)
        #expect(audioPlayer.playCallCount == 1) // no new play, just seek
    }

    // MARK: - Seek

    @Test func test_send_seek_seeksToTimeOnEnd() {
        let (sut, audioPlayer, _) = makeSUT()

        sut.send(.seekStarted)
        sut.send(.seekChanged(15.0))
        #expect(sut.isSeeking == true)
        #expect(sut.currentTime == 15.0)
        #expect(audioPlayer.seekCallCount == 0) // not yet committed

        sut.send(.seekEnded(15.0))
        #expect(sut.isSeeking == false)
        #expect(audioPlayer.seekCallCount == 1)
        #expect(audioPlayer.lastSeekTime == 15.0)
    }

    // MARK: - Repeat

    @Test func test_send_toggleRepeat_cyclesModes() {
        let (sut, _, _) = makeSUT()

        #expect(sut.repeatMode == .off)

        sut.send(.toggleRepeat)
        #expect(sut.repeatMode == .one)

        sut.send(.toggleRepeat)
        #expect(sut.repeatMode == .all)

        sut.send(.toggleRepeat)
        #expect(sut.repeatMode == .off)
    }

    // MARK: - Formatting

    @Test func test_currentTimeFormatted_formatsCorrectly() {
        let (sut, _, _) = makeSUT()
        sut.send(.seekEnded(86)) // 1:26

        #expect(sut.currentTimeFormatted == "1:26")
    }

    @Test func test_remainingTimeFormatted_formatsCorrectly() async throws {
        let (sut, audioPlayer, _) = makeSUT()
        audioPlayer._duration = 260
        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(50))
        audioPlayer.simulateTimeUpdate(86)
        try await Task.sleep(for: .milliseconds(50))

        #expect(sut.remainingTimeFormatted == "-2:54")
    }

    // MARK: - Progress

    @Test func test_progress_calculatesCorrectly() async throws {
        let (sut, audioPlayer, _) = makeSUT()
        audioPlayer._duration = 100
        sut.send(.onAppear)
        try await Task.sleep(for: .milliseconds(50))
        audioPlayer.simulateTimeUpdate(50)
        try await Task.sleep(for: .milliseconds(50))

        #expect(sut.progress == 0.5)
    }

    @Test func test_progress_whenDurationZero_returnsZero() {
        let (sut, _, _) = makeSUT()
        #expect(sut.progress == 0)
    }
}
