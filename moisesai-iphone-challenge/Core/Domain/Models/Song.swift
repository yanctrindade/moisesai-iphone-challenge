import Foundation

struct Song: Identifiable, Hashable, Sendable {
    let id: Int
    let trackName: String
    let artistName: String
    let collectionName: String
    let collectionId: Int
    let artworkURL: URL?
    let previewURL: URL?
    let durationMillis: Int
    let genre: String
    let releaseDate: String

    var artworkURLHighRes: URL? {
        guard let artworkURL else { return nil }
        let highRes = artworkURL.absoluteString.replacingOccurrences(of: "100x100", with: "600x600")
        return URL(string: highRes)
    }

    var formattedDuration: String {
        let totalSeconds = durationMillis / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Song {
    init(from dto: iTunesTrack) {
        self.id = dto.trackId ?? 0
        self.trackName = dto.trackName ?? ""
        self.artistName = dto.artistName ?? ""
        self.collectionName = dto.collectionName ?? ""
        self.collectionId = dto.collectionId ?? 0
        self.artworkURL = dto.artworkUrl100.flatMap { URL(string: $0) }
        self.previewURL = dto.previewUrl.flatMap { URL(string: $0) }
        self.durationMillis = dto.trackTimeMillis ?? 0
        self.genre = dto.primaryGenreName ?? ""
        self.releaseDate = dto.releaseDate ?? ""
    }
}
