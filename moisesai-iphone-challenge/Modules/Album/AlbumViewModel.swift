import Foundation
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "AlbumViewModel")

@Observable
@MainActor
final class AlbumViewModel {

    // MARK: - ViewState

    enum ViewState {
        case loading
        case loaded([Song])
        case error(String)
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case retry
    }

    // MARK: - Properties

    private(set) var state: ViewState = .loading
    let collectionName: String
    let artworkURL: URL?

    private let collectionId: Int
    private let fetchAlbumSongsUseCase: FetchAlbumSongsUseCaseProtocol
    private var hasLoaded = false
    private var isFetching = false

    // MARK: - Computed

    var artistName: String {
        if case .loaded(let songs) = state, let first = songs.first {
            return first.artistName
        }
        return ""
    }

    var songs: [Song] {
        if case .loaded(let songs) = state {
            return songs
        }
        return []
    }

    // MARK: - Init

    init(
        collectionId: Int,
        collectionName: String,
        artworkURL: URL?,
        fetchAlbumSongsUseCase: FetchAlbumSongsUseCaseProtocol
    ) {
        self.collectionId = collectionId
        self.collectionName = collectionName
        self.artworkURL = artworkURL
        self.fetchAlbumSongsUseCase = fetchAlbumSongsUseCase
    }

    // MARK: - Actions

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            guard !hasLoaded, !isFetching else { return }
            Task { await fetchSongs() }
        case .retry:
            guard !isFetching else { return }
            Task { await fetchSongs() }
        }
    }

    // MARK: - Private

    private func fetchSongs() async {
        isFetching = true
        state = .loading

        do {
            let songs = try await fetchAlbumSongsUseCase.execute(collectionId: collectionId)
            state = .loaded(songs)
            hasLoaded = true
        } catch {
            logger.error("Failed to fetch album songs: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
        isFetching = false
    }
}
