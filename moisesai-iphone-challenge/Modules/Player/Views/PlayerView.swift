import SwiftUI
import SwiftData

struct PlayerView: View {
    @State var viewModel: PlayerViewModel
    @Environment(Router.self) private var router
    @State private var showMoreOptions = false
    @State private var sliderValue: Double = 0
    @State private var isDragging = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                artworkView
                Spacer().frame(height: Spacing.xxxl)
                songInfoView
                Spacer().frame(height: Spacing.xxl)
                timelineView
                Spacer().frame(height: Spacing.xxl)
                transportControls
                Spacer()
            }
            .padding(.horizontal, Spacing.xxl)
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
                    MarqueeText(
                        text: viewModel.song.collectionName,
                        font: Typography.navBarTitle,
                        color: .white,
                        maxWidth: Sizing.marqueeMaxWidth
                    )
                }
                .accessibilityLabel(viewModel.song.collectionName)
                .accessibilityHint(L10n.viewAlbum)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showMoreOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.white)
                }
                .accessibilityLabel(L10n.moreOptions(for: viewModel.song.trackName))
            }
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
        .onDisappear {
            viewModel.send(.stop)
        }
        .sheet(isPresented: $showMoreOptions) {
            MoreOptionsSheet(
                song: viewModel.song,
                onViewAlbum: {
                    router.push(.album(
                        collectionId: viewModel.song.collectionId,
                        collectionName: viewModel.song.collectionName,
                        artworkURL: viewModel.song.artworkURL
                    ))
                }
            )
        }
    }

    // MARK: - Artwork

    private var artworkView: some View {
        CachedAsyncImage(url: viewModel.song.artworkURLHighRes) {
            artworkPlaceholder
        }
        .id(viewModel.song.id)
        .frame(width: Sizing.playerArtwork, height: Sizing.playerArtwork)
        .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadiusLarge))
        .animation(.easeInOut(duration: 0.3), value: viewModel.song.id)
        .accessibilityLabel(L10n.albumArt(viewModel.song.collectionName))
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: Sizing.cornerRadiusLarge)
            .fill(Color(.tertiarySystemBackground))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Song Info

    private var songInfoView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.song.trackName)
                    .font(Typography.playerSongTitle)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .id(viewModel.song.id)

                Text(viewModel.song.artistName)
                    .font(Typography.playerArtistName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.song.id)

            Spacer()

            Button {
                viewModel.send(.toggleRepeat)
            } label: {
                Image(systemName: repeatIcon)
                    .font(Typography.repeatIcon)
                    .foregroundStyle(viewModel.repeatMode == .off ? Color.secondary : Color.white)
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.repeatMode)
            .accessibilityLabel(L10n.repeatMode)
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
        case .off: L10n.repeatOff
        case .one: L10n.repeatOne
        case .all: L10n.repeatAll
        }
    }

    // MARK: - Timeline

    private var timelineView: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { isDragging ? sliderValue : viewModel.currentTime },
                    set: { newValue in
                        sliderValue = newValue
                        if !isDragging {
                            isDragging = true
                            viewModel.send(.seekStarted)
                        }
                        viewModel.send(.seekChanged(newValue))
                    }
                ),
                in: 0...max(viewModel.duration, 1),
                onEditingChanged: { editing in
                    if !editing {
                        isDragging = false
                        viewModel.send(.seekEnded(sliderValue))
                    }
                }
            )
            .tint(.white)
            .accessibilityLabel(L10n.seekSlider)

            HStack {
                Text(viewModel.currentTimeFormatted)
                    .font(Typography.timeLabel)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Text(viewModel.remainingTimeFormatted)
                    .font(Typography.timeLabel)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Transport Controls

    private var transportControls: some View {
        HStack(spacing: Spacing.huge) {
            Button {
                viewModel.send(.backward)
            } label: {
                Image(systemName: "backward.fill")
                    .font(Typography.transportIcon)
                    .foregroundStyle(.white)
                    .frame(width: Sizing.tapTarget, height: Sizing.tapTarget)
            }
            .accessibilityLabel(L10n.backward)

            Button {
                viewModel.send(.playPause)
            } label: {
                Image(systemName: viewModel.state == .playing ? "pause.fill" : "play.fill")
                    .font(Typography.playPauseIcon)
                    .foregroundStyle(.white)
                    .frame(width: Sizing.playPauseButton, height: Sizing.playPauseButton)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Circle())
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(L10n.playPause)

            Button {
                viewModel.send(.forward)
            } label: {
                Image(systemName: "forward.fill")
                    .font(Typography.transportIcon)
                    .foregroundStyle(.white)
                    .frame(width: Sizing.tapTarget, height: Sizing.tapTarget)
            }
            .accessibilityLabel(L10n.forward)
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
    let container = try! ModelContainer(
        for: CachedSong.self, RecentlyPlayedSong.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    NavigationStack {
        PlayerView(
            viewModel: PlayerViewModel(
                song: previewSong,
                playlist: [previewSong],
                audioPlayer: AudioPlayerService.shared,
                saveRecentlyPlayedUseCase: SaveRecentlyPlayedUseCase(
                    repository: SongsRepository(networkService: URLSessionNetworkService(), modelContainer: container)
                )
            )
        )
    }
    .environment(Router())
    .preferredColorScheme(.dark)
}
