import SwiftUI

struct HomeView: View {
    @State var viewModel: HomeViewModel
    @Environment(Router.self) private var router
    @State private var isSearching = false
    @State private var selectedSongForOptions: Song?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if isSearching {
                    searchingHeader
                } else {
                    defaultHeader
                }

                contentView
            }
        }
        .navigationBarHidden(true)
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
    }

    // MARK: - Default Header (search icon + centered title)

    private var defaultHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isSearching = true
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(NSLocalizedString("accessibility.search", comment: ""))

            Spacer()

            Text(NSLocalizedString("songs.title", comment: ""))
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Searching Header (large title + search bar)

    private var searchingHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("songs.title", comment: ""))
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField(
                        NSLocalizedString("songs.search.placeholder", comment: ""),
                        text: Binding(
                            get: { viewModel.searchText },
                            set: { viewModel.searchText = $0 }
                        )
                    )
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(.primary)
                    .onSubmit {
                        if !viewModel.searchText.isEmpty {
                            viewModel.send(.search(viewModel.searchText))
                        }
                    }

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.searchText = ""
                        isSearching = false
                    }
                } label: {
                    Text(NSLocalizedString("general.cancel", comment: ""))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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
            LoadingView(message: NSLocalizedString("general.loading", comment: ""))
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
    let networkService = URLSessionNetworkService()
    let repository = SongsRepository(networkService: networkService)
    let searchUseCase = SearchSongsUseCase(repository: repository)
    let recentlyPlayedUseCase = GetRecentlyPlayedUseCase(repository: repository)

    HomeView(
        viewModel: HomeViewModel(
            searchSongsUseCase: searchUseCase,
            getRecentlyPlayedUseCase: recentlyPlayedUseCase
        )
    )
    .environment(Router())
    .preferredColorScheme(.dark)
}
