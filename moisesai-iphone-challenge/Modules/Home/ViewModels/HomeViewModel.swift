import Foundation
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "HomeViewModel")

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - ViewState

    enum ViewState {
        case idle
        case loading
        case loaded([Song])
        case error(String)
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case search(String)
        case loadMore
        case clearSearch
    }

    // MARK: - Constants

    private enum Constants {
        static let pageSize = 20
    }

    // MARK: - Properties

    private(set) var state: ViewState = .idle
    private(set) var recentlyPlayed: [Song] = []
    /// TrackIds that have audio cached to disk. Populated from `audioCache` on appear and on song list updates.
    /// Views read from this set instead of hitting the file system per row during rendering.
    private(set) var cachedTrackIds: Set<Int> = []
    /// True once initial recently-played load has completed. Splash uses this to hold until Home is interactive.
    private(set) var isReady: Bool = false
    var searchText: String = "" {
        didSet { handleSearchTextChanged() }
    }
    private(set) var isLoadingMore = false
    private(set) var hasMorePages = true

    private var currentOffset = 0
    private var currentTerm = ""
    private var songs: [Song] = []
    private var searchTask: Task<Void, Never>?

    private let searchSongsUseCase: SearchSongsUseCaseProtocol
    private let getRecentlyPlayedUseCase: GetRecentlyPlayedUseCaseProtocol
    private let audioCache: AudioCacheServiceProtocol

    // MARK: - Init

    init(
        searchSongsUseCase: SearchSongsUseCaseProtocol,
        getRecentlyPlayedUseCase: GetRecentlyPlayedUseCaseProtocol,
        audioCache: AudioCacheServiceProtocol = AudioCacheService.shared
    ) {
        self.searchSongsUseCase = searchSongsUseCase
        self.getRecentlyPlayedUseCase = getRecentlyPlayedUseCase
        self.audioCache = audioCache
    }

    func isCached(_ song: Song) -> Bool {
        cachedTrackIds.contains(song.id)
    }

    // MARK: - Actions

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            // Always refresh recently-played on appear so returning from Player
            // picks up the just-played song. preload() handles the first-load
            // gating separately.
            Task { await loadRecentlyPlayed() }
        case .search(let term):
            performSearch(term)
        case .loadMore:
            Task { await loadNextPage() }
        case .clearSearch:
            clearSearch()
        }
    }

    /// Awaitable initial load. Callers (e.g., SplashView) can `await` this to know
    /// when Home is ready to be shown without the UI feeling frozen on first launch.
    /// Subsequent calls are no-ops once `isReady` is true.
    func preload() async {
        guard !isReady else { return }
        await loadRecentlyPlayed()
        isReady = true
    }

    func refresh() async {
        if currentTerm.isEmpty {
            await loadRecentlyPlayed()
        } else {
            currentOffset = 0
            hasMorePages = true

            let requestedTerm = currentTerm

            do {
                let results = try await searchSongsUseCase.execute(
                    term: requestedTerm,
                    limit: Constants.pageSize,
                    offset: 0
                )
                guard currentTerm == requestedTerm else { return }
                songs = results
                hasMorePages = results.count >= Constants.pageSize
                currentOffset = results.count
                state = results.isEmpty ? .idle : .loaded(songs)
                refreshCachedTrackIds()
            } catch {
                if songs.isEmpty {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Private

    private func handleSearchTextChanged() {
        searchTask?.cancel()

        if searchText.isEmpty {
            clearSearch()
            return
        }

        // Immediately show loading so the user doesn't see stale "no results"
        // during the debounce window. If the current term already has cached
        // results, keep showing them (avoid flicker).
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            clearSearch()
            return
        }

        if case .loaded = state {
            // keep previous results visible during debounce
        } else {
            state = .loading
        }

        searchTask = Task {
            try? await Task.sleep(for: Timing.searchDebounce)
            guard !Task.isCancelled else { return }
            await executeSearch(searchText)
        }
    }

    private func performSearch(_ term: String) {
        searchTask?.cancel()
        searchTask = Task {
            await executeSearch(term)
        }
    }

    private func executeSearch(_ term: String) async {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else {
            clearSearch()
            return
        }

        currentTerm = trimmedTerm
        currentOffset = 0
        hasMorePages = true

        let cached = await searchSongsUseCase.cachedResults(for: trimmedTerm)
        if !cached.isEmpty {
            songs = cached
            state = .loaded(songs)
            refreshCachedTrackIds()
        } else {
            state = .loading
        }

        do {
            let results = try await searchSongsUseCase.execute(
                term: trimmedTerm,
                limit: Constants.pageSize,
                offset: 0
            )
            guard trimmedTerm == currentTerm, !Task.isCancelled else { return }
            songs = results
            hasMorePages = results.count >= Constants.pageSize
            currentOffset = results.count
            state = results.isEmpty ? .idle : .loaded(songs)
            refreshCachedTrackIds()
        } catch {
            guard trimmedTerm == currentTerm, !Task.isCancelled else { return }
            if songs.isEmpty {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func loadNextPage() async {
        guard !isLoadingMore, hasMorePages, !currentTerm.isEmpty else { return }

        isLoadingMore = true

        do {
            let results = try await searchSongsUseCase.execute(
                term: currentTerm,
                limit: Constants.pageSize,
                offset: currentOffset
            )
            songs.append(contentsOf: results)
            hasMorePages = results.count >= Constants.pageSize
            currentOffset += results.count
            state = .loaded(songs)
            refreshCachedTrackIds()
        } catch {
            logger.error("Failed to load next page: \(error.localizedDescription)")
        }

        isLoadingMore = false
    }

    private func loadRecentlyPlayed() async {
        recentlyPlayed = await getRecentlyPlayedUseCase.execute()
        await refreshCachedTrackIdsAsync()
    }

    private func refreshCachedTrackIds() {
        // Fire-and-forget background refresh so callers (search, pagination, etc.)
        // don't stall the MainActor on disk I/O per song.
        Task { await refreshCachedTrackIdsAsync() }
    }

    private func refreshCachedTrackIdsAsync() async {
        let ids = (songs + recentlyPlayed).map(\.id)
        let cache = audioCache
        let cached = await Task.detached(priority: .utility) {
            Set(ids.filter { cache.hasCache(for: $0) })
        }.value
        cachedTrackIds = cached
    }

    private func clearSearch() {
        searchTask?.cancel()
        currentTerm = ""
        currentOffset = 0
        songs = []
        hasMorePages = true
        state = .idle
        refreshCachedTrackIds()
    }
}
