import SwiftUI

struct MoreOptionsSheet: View {
    let song: Song
    var onViewAlbum: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var shareText: String {
        "\(song.trackName) - \(song.artistName)"
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Song info header
            VStack(spacing: Spacing.xs) {
                Text(song.trackName)
                    .font(Typography.sheetTitle)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(Typography.songSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.top, Spacing.xxl)

            Divider()
                .overlay(Color(.systemGray4))

            // Options
            VStack(spacing: 0) {
                Button {
                    dismiss()
                    onViewAlbum()
                } label: {
                    HStack(spacing: Spacing.md) {
                        Image("ViewAlbumIcon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)

                        Text(Strings.viewAlbum)
                            .font(Typography.sheetButton)
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, Spacing.xs)
                }

                shareLink
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Sizing.cornerRadiusSheet)
        .presentationBackground {
            AppColors.sheetBackground
                .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var shareLink: some View {
        if let url = song.previewURL {
            ShareLink(
                item: url,
                subject: Text(song.trackName),
                message: Text(shareText)
            ) {
                shareLinkLabel
            }
        } else {
            ShareLink(item: shareText) {
                shareLinkLabel
            }
        }
    }

    private var shareLinkLabel: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "square.and.arrow.up")
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)

            Text(Strings.share)
                .font(Typography.sheetButton)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.xs)
    }
}

extension MoreOptionsSheet {
    enum Strings {
        static let viewAlbum = NSLocalizedString("moreOptions.viewAlbum", comment: "")
        static let share = NSLocalizedString("moreOptions.share", comment: "")
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
                onViewAlbum: {}
            )
        }
        .preferredColorScheme(.dark)
}
