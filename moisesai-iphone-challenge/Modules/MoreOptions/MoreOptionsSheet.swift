import SwiftUI

struct MoreOptionsSheet: View {
    let song: Song
    var onViewAlbum: () -> Void
    var onShare: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text(song.trackName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.top, 20)
                .padding(.bottom, 4)

            Button {
                dismiss()
                onViewAlbum()
            } label: {
                Text(NSLocalizedString("moreOptions.viewAlbum", comment: ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                dismiss()
                onShare()
            } label: {
                Text(NSLocalizedString("moreOptions.share", comment: ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.black)
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.black)
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            MoreOptionsSheet(
                song: Song(
                    id: 1, trackName: "LOVE. (feat. Zacari)",
                    artistName: "Kendrick Lamar",
                    collectionName: "DAMN.",
                    collectionId: 100, artworkURL: nil, previewURL: nil,
                    durationMillis: 213000, genre: "Hip-Hop",
                    releaseDate: "2017-04-14"
                ),
                onViewAlbum: {},
                onShare: {}
            )
        }
        .preferredColorScheme(.dark)
}
