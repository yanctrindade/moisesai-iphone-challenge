import SwiftUI

struct SongRowView: View {
    let song: Song
    let showMoreButton: Bool
    var onMoreTapped: (() -> Void)?

    init(song: Song, showMoreButton: Bool = true, onMoreTapped: (() -> Void)? = nil) {
        self.song = song
        self.showMoreButton = showMoreButton
        self.onMoreTapped = onMoreTapped
    }

    var body: some View {
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
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 50, height: 50)
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

            if showMoreButton {
                Button {
                    onMoreTapped?()
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(format: NSLocalizedString("accessibility.songRow.moreOptions", comment: ""), song.trackName))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: NSLocalizedString("accessibility.songRow", comment: ""), song.trackName, song.artistName))
        .accessibilityAddTraits(.isButton)
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
