import SwiftUI

struct MoreOptionsSheet: View {
    let song: Song
    var onViewAlbum: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var shareText: String {
        "\(song.trackName) - \(song.artistName)"
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
        HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: Sizing.sheetButtonIconSize))
                .foregroundStyle(.white)
            Text(Strings.share)
                .font(Typography.sheetButton)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Sizing.sheetButtonPadding)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadiusLarge))
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(song.trackName)
                .font(Typography.sheetTitle)
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.top, Spacing.xl)
                .padding(.bottom, 4)

            Button {
                dismiss()
                onViewAlbum()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: Sizing.sheetButtonIconSize))
                        .foregroundStyle(.white)
                    Text(Strings.viewAlbum)
                        .font(Typography.sheetButton)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Sizing.sheetButtonPadding)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadiusLarge))
            }

            shareLink

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .presentationDetents([.height(Sizing.moreOptionsSheetHeight)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Sizing.cornerRadiusSheet)
        .presentationBackground {
            AppColors.sheetBackground
                .background(.ultraThinMaterial)
        }
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
