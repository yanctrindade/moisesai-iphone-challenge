import SwiftUI

struct PlayerView: View {
    @State var viewModel: PlayerViewModel
    @Environment(Router.self) private var router
    @State private var showMoreOptions = false
    @State private var sliderValue: Double = 0
    @State private var isDragging = false

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
                    MarqueeText(
                        text: viewModel.song.collectionName,
                        font: .system(size: 16, weight: .semibold),
                        color: .white,
                        maxWidth: 200
                    )
                }
                .accessibilityLabel(viewModel.song.collectionName)
                .accessibilityHint(NSLocalizedString("moreOptions.viewAlbum", comment: ""))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showMoreOptions = true
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
        .sheet(isPresented: $showMoreOptions) {
            MoreOptionsSheet(
                song: viewModel.song,
                onViewAlbum: {
                    router.push(.album(
                        collectionId: viewModel.song.collectionId,
                        collectionName: viewModel.song.collectionName,
                        artworkURL: viewModel.song.artworkURL
                    ))
                },
                onShare: {
                    shareSong(viewModel.song)
                }
            )
        }
    }

    // MARK: - Artwork

    private var artworkView: some View {
        AsyncImage(url: viewModel.song.artworkURLHighRes) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            case .failure:
                artworkPlaceholder
            case .empty:
                artworkPlaceholder
                    .overlay { ProgressView().tint(.secondary) }
            @unknown default:
                artworkPlaceholder
            }
        }
        .id(viewModel.song.id)
        .frame(width: 264, height: 264)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: viewModel.song.id)
        .accessibilityLabel(
            String(format: NSLocalizedString("accessibility.player.albumArt", comment: ""), viewModel.song.collectionName)
        )
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
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
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .id(viewModel.song.id)

                Text(viewModel.song.artistName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.song.id)

            Spacer()

            Button {
                viewModel.send(.toggleRepeat)
            } label: {
                Image(systemName: repeatIcon)
                    .font(.title3)
                    .foregroundStyle(viewModel.repeatMode == .off ? Color.secondary : Color.white)
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.repeatMode)
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
        case .off: NSLocalizedString("accessibility.player.repeat.off", comment: "")
        case .one: NSLocalizedString("accessibility.player.repeat.one", comment: "")
        case .all: NSLocalizedString("accessibility.player.repeat.all", comment: "")
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
                    .contentTransition(.symbolEffect(.replace))
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

    // MARK: - Helpers

    private func shareSong(_ song: Song) {
        var items: [Any] = ["\(song.trackName) - \(song.artistName)"]
        if let url = song.previewURL {
            items.append(url)
        }
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
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
