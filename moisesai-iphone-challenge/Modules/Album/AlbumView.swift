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
                trackRow(song, playlist: songs)
            }
        }
    }

    private func trackRow(_ song: Song, playlist: [Song]) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: song.artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(song.trackName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            router.push(.player(song: song, playlist: playlist))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: NSLocalizedString("accessibility.songRow", comment: ""), song.trackName, song.artistName))
        .accessibilityAddTraits(.isButton)
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
