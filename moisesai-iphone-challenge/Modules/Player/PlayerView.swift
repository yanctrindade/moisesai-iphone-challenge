import SwiftUI

struct PlayerView: View {
    @State var viewModel: PlayerViewModel
    @Environment(Router.self) private var router
    @State private var selectedSongForOptions: Song?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                artworkView
                Spacer().frame(height: 32)
                songInfoView
                Spacer().frame(height: 24)
                timelineView
                Spacer().frame(height: 24)
                transportControls
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .tint(.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    router.push(.album(
                        collectionId: viewModel.song.collectionId,
                        collectionName: viewModel.song.collectionName,
                        artworkURL: viewModel.song.artworkURL
                    ))
                } label: {
                    Text(viewModel.song.collectionName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .accessibilityLabel(viewModel.song.collectionName)
                .accessibilityHint(NSLocalizedString("moreOptions.viewAlbum", comment: ""))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedSongForOptions = viewModel.song
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.white)
                }
                .accessibilityLabel(
                    String(format: NSLocalizedString("accessibility.songRow.moreOptions", comment: ""), viewModel.song.trackName)
                )
            }
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
        .sheet(item: $selectedSongForOptions) { song in
            Text(song.trackName)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Artwork

    private var artworkView: some View {
        AsyncImage(url: viewModel.song.artworkURLHighRes) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                }
        }
        .frame(width: 264, height: 264)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(
            String(format: NSLocalizedString("accessibility.player.albumArt", comment: ""), viewModel.song.collectionName)
        )
    }

    // MARK: - Song Info

    private var songInfoView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.song.trackName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(viewModel.song.artistName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                viewModel.send(.toggleRepeat)
            } label: {
                Image(systemName: repeatIcon)
                    .font(.title3)
                    .foregroundStyle(viewModel.repeatMode == .off ? Color.secondary : Color.white)
            }
            .accessibilityLabel(NSLocalizedString("accessibility.player.repeat", comment: ""))
            .accessibilityValue(repeatAccessibilityValue)
        }
    }

    private var repeatIcon: String {
        switch viewModel.repeatMode {
        case .off: "repeat"
        case .one: "repeat.1"
        case .all: "repeat"
        }
    }

    private var repeatAccessibilityValue: String {
        switch viewModel.repeatMode {
        case .off: "Off"
        case .one: "Repeat one"
        case .all: "Repeat all"
        }
    }

    // MARK: - Timeline

    private var timelineView: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.send(.seek($0)) }
                ),
                in: 0...max(viewModel.duration, 1)
            )
            .tint(.white)
            .accessibilityLabel(NSLocalizedString("accessibility.player.seekSlider", comment: ""))

            HStack {
                Text(viewModel.currentTimeFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Text(viewModel.remainingTimeFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Transport Controls

    private var transportControls: some View {
        HStack(spacing: 40) {
            Button {
                viewModel.send(.backward)
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(NSLocalizedString("accessibility.player.backward", comment: ""))

            Button {
                viewModel.send(.playPause)
            } label: {
                Image(systemName: viewModel.state == .playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Circle())
            }
            .accessibilityLabel(NSLocalizedString("accessibility.player.playPause", comment: ""))

            Button {
                viewModel.send(.forward)
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(NSLocalizedString("accessibility.player.forward", comment: ""))
        }
    }
}

#Preview {
    let previewSong = Song(
        id: 1, trackName: "Get Lucky",
        artistName: "Daft Punk feat. Pharrell Williams",
        collectionName: "Random Access Memories",
        collectionId: 100, artworkURL: nil, previewURL: nil,
        durationMillis: 248000, genre: "Electronic",
        releaseDate: "2013-05-17"
    )

    NavigationStack {
        PlayerView(
            viewModel: PlayerViewModel(
                song: previewSong,
                playlist: [previewSong],
                audioPlayer: AudioPlayerService(),
                saveRecentlyPlayedUseCase: SaveRecentlyPlayedUseCase(
                    repository: SongsRepository(networkService: URLSessionNetworkService())
                )
            )
        )
    }
    .environment(Router())
    .preferredColorScheme(.dark)
}
