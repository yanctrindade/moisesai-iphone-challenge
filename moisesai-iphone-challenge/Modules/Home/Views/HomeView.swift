import SwiftUI
import SwiftData

struct HomeView: View {
    @State var viewModel: HomeViewModel
    @Environment(Router.self) private var router
    @State private var isSearchActive = false
    @State private var selectedSongForOptions: Song?

    var body: some View {
        contentView
            .navigationTitle(NSLocalizedString("songs.title", comment: ""))
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.searchText = $0 }
                ),
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: NSLocalizedString("songs.search.placeholder", comment: "")
            )
            .onAppear {
                viewModel.send(.onAppear)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(item: $selectedSongForOptions) { song in
                Text(song.trackName)
                    .presentationDetents([.medium])
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
                        NSLocalizedString("songs.empty.title", comment: ""),
                        systemImage: "music.note"
                    )
                } description: {
                    Text(NSLocalizedString("songs.empty.message", comment: ""))
                }
                .padding(.top, 100)
            }
        }
    }

    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("songs.recentlyPlayed", comment: ""))
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .accessibilityAddTraits(.isHeader)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.recentlyPlayed) { song in
                    SongRowView(song: song, showMoreButton: true) {
                        selectedSongForOptions = song
                    }
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        router.push(.player(song: song, playlist: viewModel.recentlyPlayed))
                    }
                }
            }
        }
        .padding(.top, 16)
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
                    .padding(.horizontal, 16)
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
