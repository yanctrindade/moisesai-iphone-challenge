import Foundation

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
        case refresh
        case clearSearch
    }

    // MARK: - Constants

    private enum Constants {
        static let pageSize = 20
        static let debounceDelay: Duration = .milliseconds(500)
    }

    // MARK: - Properties

    private(set) var state: ViewState = .idle
    private(set) var recentlyPlayed: [Song] = []
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

    // MARK: - Init

    init(
        searchSongsUseCase: SearchSongsUseCaseProtocol,
        getRecentlyPlayedUseCase: GetRecentlyPlayedUseCaseProtocol
    ) {
        self.searchSongsUseCase = searchSongsUseCase
        self.getRecentlyPlayedUseCase = getRecentlyPlayedUseCase
    }

    // MARK: - Actions

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            Task { await loadRecentlyPlayed() }
        case .search(let term):
            performSearch(term)
        case .loadMore:
            Task { await loadNextPage() }
        case .refresh:
            Task { await refresh() }
        case .clearSearch:
            clearSearch()
        }
    }

    // MARK: - Private

    private func handleSearchTextChanged() {
        searchTask?.cancel()

        if searchText.isEmpty {
            clearSearch()
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: Constants.debounceDelay)
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
        guard !trimmedTerm.isEmpty else { return }

        currentTerm = trimmedTerm
        currentOffset = 0
        hasMorePages = true

        let cached = await searchSongsUseCase.cachedResults(for: trimmedTerm)
        if !cached.isEmpty {
            songs = cached
            state = .loaded(songs)
        } else {
            state = .loading
        }

        do {
            let results = try await searchSongsUseCase.execute(
                term: trimmedTerm,
                limit: Constants.pageSize,
                offset: 0
            )
            songs = results
            hasMorePages = results.count >= Constants.pageSize
            currentOffset = results.count
            state = results.isEmpty ? .idle : .loaded(songs)
        } catch {
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
        } catch {
            // Keep existing data, just stop loading more
        }

        isLoadingMore = false
    }

    private func refresh() async {
        if currentTerm.isEmpty {
            await loadRecentlyPlayed()
        } else {
            currentOffset = 0
            hasMorePages = true

            do {
                let results = try await searchSongsUseCase.execute(
                    term: currentTerm,
                    limit: Constants.pageSize,
                    offset: 0
                )
                songs = results
                hasMorePages = results.count >= Constants.pageSize
                currentOffset = results.count
                state = results.isEmpty ? .idle : .loaded(songs)
            } catch {
                if songs.isEmpty {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }

    private func loadRecentlyPlayed() async {
        recentlyPlayed = await getRecentlyPlayedUseCase.execute()
    }

    private func clearSearch() {
        searchTask?.cancel()
        currentTerm = ""
        currentOffset = 0
        songs = []
        hasMorePages = true
        state = .idle
    }
}
