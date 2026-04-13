import SwiftUI

struct AlbumView: View {
    @State var viewModel: AlbumViewModel
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                SkeletonListView(count: 6)
            case .loaded(let songs) where songs.isEmpty:
                emptyStateView
            case .loaded(let songs):
                albumContent(songs)
            case .error(let message):
                ErrorStateView(message: message) {
                    viewModel.send(.retry)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
        .onAppear {
            viewModel.send(.onAppear)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            albumHeader

            ContentUnavailableView {
                Label(Strings.emptyTitle, systemImage: "music.note.list")
            } description: {
                Text(Strings.emptyMessage)
            }
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Album Content

    private func albumContent(_ songs: [Song]) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                albumHeader
                trackList(songs)
            }
            .padding(.top, Spacing.lg)
        }
    }

    // MARK: - Header

    private var albumHeader: some View {
        VStack(spacing: 8) {
            CachedAsyncImage(url: viewModel.artworkURL) {
                RoundedRectangle(cornerRadius: Sizing.cornerRadiusMedium)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: Sizing.albumHeaderArtwork, height: Sizing.albumHeaderArtwork)
            .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadiusMedium))

            Text(viewModel.collectionName)
                .font(Typography.albumTitle)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(viewModel.artistName)
                .font(Typography.albumArtist)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Track List

    private func trackList(_ songs: [Song]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(songs) { song in
                SongRowView(song: song, showMoreButton: false, artworkSize: Sizing.albumTrackArtwork)
                    .padding(.horizontal, Spacing.lg)
                    .onTapGesture {
                        router.push(.player(song: song, playlist: songs))
                    }
            }
        }
    }
}

extension AlbumView {
    enum Strings {
        static let emptyTitle = NSLocalizedString("album.empty.title", comment: "")
        static let emptyMessage = NSLocalizedString("album.empty.message", comment: "")
    }
}

#Preview {
    NavigationStack {
        AlbumView(
            viewModel: AlbumViewModel(
                collectionId: 1440742903,
                collectionName: "Random Access Memories",
                artworkURL: nil,
                fetchAlbumSongsUseCase: FetchAlbumSongsUseCase(
                    networkService: URLSessionNetworkService()
                )
            )
        )
    }
    .environment(Router())
    .preferredColorScheme(.dark)
}
