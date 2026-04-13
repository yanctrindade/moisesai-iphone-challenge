import SwiftUI
import SwiftData

struct HomeView: View {
    @State var viewModel: HomeViewModel
    @Environment(Router.self) private var router
    @State private var isSearchActive = false
    @State private var selectedSongForOptions: Song?

    var body: some View {
        contentView
            .navigationTitle(Strings.songsTitle)
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.searchText = $0 }
                ),
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: Strings.searchPlaceholder
            )
            .onAppear {
                viewModel.send(.onAppear)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(item: $selectedSongForOptions) { song in
                MoreOptionsSheet(
                    song: song,
                    onViewAlbum: {
                        selectedSongForOptions = nil
                        router.push(.album(
                            collectionId: song.collectionId,
                            collectionName: song.collectionName,
                            artworkURL: song.artworkURL
                        ))
                    }
                )
            }
            .onSubmit(of: .search) {
                if !viewModel.searchText.isEmpty {
                    viewModel.send(.search(viewModel.searchText))
                }
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            if viewModel.searchText.isEmpty {
                idleView
            } else {
                emptySearchView
            }
        case .loading:
            SkeletonListView()
        case .loaded(let songs):
            songListView(songs)
        case .error(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.refresh() }
            }
        }
    }

    private var idleView: some View {
        ScrollView {
            if !viewModel.recentlyPlayed.isEmpty {
                recentlyPlayedSection
            } else {
                ContentUnavailableView {
                    Label(
                        Strings.emptyTitle,
                        systemImage: "music.note"
                    )
                } description: {
                    Text(Strings.emptyMessage)
                }
                .padding(.top, 100)
            }
        }
    }

    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.recentlyPlayed)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, Spacing.lg)
                .accessibilityAddTraits(.isHeader)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.recentlyPlayed) { song in
                    SongRowView(song: song, showMoreButton: true) {
                        selectedSongForOptions = song
                    }
                    .padding(.horizontal, Spacing.lg)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        router.push(.player(song: song, playlist: viewModel.recentlyPlayed))
                    }
                }
            }
        }
        .padding(.top, Spacing.lg)
    }

    private var emptySearchView: some View {
        ContentUnavailableView.search(text: viewModel.searchText)
    }

    private func songListView(_ songs: [Song]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(songs) { song in
                    SongRowView(song: song) {
                        selectedSongForOptions = song
                    }
                    .padding(.horizontal, Spacing.lg)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        router.push(.player(song: song, playlist: songs))
                    }
                    .onAppear {
                        if song.id == songs.last?.id {
                            viewModel.send(.loadMore)
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
        }
    }
}

extension HomeView {
    enum Strings {
        static let songsTitle = NSLocalizedString("songs.title", comment: "")
        static let searchPlaceholder = NSLocalizedString("songs.search.placeholder", comment: "")
        static let emptyTitle = NSLocalizedString("songs.empty.title", comment: "")
        static let emptyMessage = NSLocalizedString("songs.empty.message", comment: "")
        static let recentlyPlayed = NSLocalizedString("songs.recentlyPlayed", comment: "")
    }
}

#Preview {
    let container = try! ModelContainer(
        for: CachedSong.self, RecentlyPlayedSong.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let networkService = URLSessionNetworkService()
    let repository = SongsRepository(networkService: networkService, modelContainer: container)
    let searchUseCase = SearchSongsUseCase(repository: repository)
    let recentlyPlayedUseCase = GetRecentlyPlayedUseCase(repository: repository)

    NavigationStack {
        HomeView(
            viewModel: HomeViewModel(
                searchSongsUseCase: searchUseCase,
                getRecentlyPlayedUseCase: recentlyPlayedUseCase
            )
        )
    }
    .environment(Router())
    .preferredColorScheme(.dark)
}
