import SwiftUI

struct SongRowView: View {
    let song: Song
    let showMoreButton: Bool
    let artworkSize: CGFloat
    let isDisabled: Bool
    var onMoreTapped: (() -> Void)?

    init(
        song: Song,
        showMoreButton: Bool = true,
        artworkSize: CGFloat = Sizing.songRowArtwork,
        isDisabled: Bool = false,
        onMoreTapped: (() -> Void)? = nil
    ) {
        self.song = song
        self.showMoreButton = showMoreButton
        self.artworkSize = artworkSize
        self.isDisabled = isDisabled
        self.onMoreTapped = onMoreTapped
    }

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: song.artworkURL) {
                RoundedRectangle(cornerRadius: Sizing.cornerRadiusSmall)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: artworkSize, height: artworkSize)
            .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadiusSmall))

            VStack(alignment: .leading, spacing: 2) {
                Text(song.trackName)
                    .font(Typography.songTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(Typography.songSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if showMoreButton {
                Button {
                    onMoreTapped?()
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .frame(width: Sizing.tapTarget, height: Sizing.tapTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Strings.moreOptions(for: song.trackName))
            }
        }
        .padding(.vertical, Spacing.xs)
        .opacity(isDisabled ? 0.4 : 1.0)
        .allowsHitTesting(!isDisabled)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Strings.songRow(song.trackName, song.artistName))
    }
}

extension SongRowView {
    enum Strings {
        static func moreOptions(for song: String) -> String {
            String(format: NSLocalizedString("accessibility.songRow.moreOptions", comment: ""), song)
        }

        static func songRow(_ song: String, _ artist: String) -> String {
            String(format: NSLocalizedString("accessibility.songRow", comment: ""), song, artist)
        }
    }
}

#Preview {
    SongRowView(
        song: Song(
            id: 1,
            trackName: "Get Lucky",
            artistName: "Daft Punk feat. Pharrell Williams",
            collectionName: "Random Access Memories",
            collectionId: 1,
            artworkURL: nil,
            previewURL: nil,
            durationMillis: 248000,
            genre: "Electronic",
            releaseDate: "2013-05-17"
        )
    )
    .padding()
    .background(.black)
    .preferredColorScheme(.dark)
}
