import Foundation

enum L10n {
    // MARK: - General
    static let loading = NSLocalizedString("general.loading", comment: "")
    static let errorTitle = NSLocalizedString("general.error.title", comment: "")
    static let tryAgain = NSLocalizedString("general.error.tryAgain", comment: "")
    static let unknown = NSLocalizedString("general.unknown", comment: "")
    static let cancel = NSLocalizedString("general.cancel", comment: "")

    // MARK: - Songs Screen
    static let songsTitle = NSLocalizedString("songs.title", comment: "")
    static let searchPlaceholder = NSLocalizedString("songs.search.placeholder", comment: "")
    static let emptyTitle = NSLocalizedString("songs.empty.title", comment: "")
    static let emptyMessage = NSLocalizedString("songs.empty.message", comment: "")
    static let recentlyPlayed = NSLocalizedString("songs.recentlyPlayed", comment: "")

    // MARK: - Player
    static let timelineRemaining = NSLocalizedString("player.timeline.remaining", comment: "")

    // MARK: - Album
    static let albumTracks = NSLocalizedString("album.tracks", comment: "")

    // MARK: - More Options
    static let viewAlbum = NSLocalizedString("moreOptions.viewAlbum", comment: "")
    static let share = NSLocalizedString("moreOptions.share", comment: "")
    static let addToFavorites = NSLocalizedString("moreOptions.addToFavorites", comment: "")
    static let removeFromFavorites = NSLocalizedString("moreOptions.removeFromFavorites", comment: "")

    // MARK: - Accessibility
    static func songRow(_ song: String, _ artist: String) -> String {
        String(format: NSLocalizedString("accessibility.songRow", comment: ""), song, artist)
    }

    static func moreOptions(for song: String) -> String {
        String(format: NSLocalizedString("accessibility.songRow.moreOptions", comment: ""), song)
    }

    static let playPause = NSLocalizedString("accessibility.player.playPause", comment: "")
    static let forward = NSLocalizedString("accessibility.player.forward", comment: "")
    static let backward = NSLocalizedString("accessibility.player.backward", comment: "")
    static let seekSlider = NSLocalizedString("accessibility.player.seekSlider", comment: "")
    static let repeatMode = NSLocalizedString("accessibility.player.repeat", comment: "")
    static let repeatOff = NSLocalizedString("accessibility.player.repeat.off", comment: "")
    static let repeatOne = NSLocalizedString("accessibility.player.repeat.one", comment: "")
    static let repeatAll = NSLocalizedString("accessibility.player.repeat.all", comment: "")
    static let search = NSLocalizedString("accessibility.search", comment: "")

    static func albumArt(_ album: String) -> String {
        String(format: NSLocalizedString("accessibility.player.albumArt", comment: ""), album)
    }
}
