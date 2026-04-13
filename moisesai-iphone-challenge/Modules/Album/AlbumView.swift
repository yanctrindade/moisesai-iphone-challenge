import SwiftUI

struct AlbumView: View {
    @State var viewModel: AlbumViewModel
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                LoadingView(message: NSLocalizedString("general.loading", comment: ""))
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

    // MARK: - Album Content

    private func albumContent(_ songs: [Song]) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                albumHeader
                trackList(songs)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Header

    private var albumHeader: some View {
        VStack(spacing: 8) {
            AsyncImage(url: viewModel.artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemBackground))
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(viewModel.collectionName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(viewModel.artistName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Track List

    private func trackList(_ songs: [Song]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(songs) { song in
                SongRowView(song: song, showMoreButton: false, artworkSize: 44)
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        router.push(.player(song: song, playlist: songs))
                    }
            }
        }
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
