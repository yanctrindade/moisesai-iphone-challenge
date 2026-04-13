import Foundation
import SwiftData

@Model
final class RecentlyPlayedSong {
    #Index<RecentlyPlayedSong>([\.trackId], [\.playedAt])

    var trackId: Int
    var trackName: String
    var artistName: String
    var collectionName: String
    var collectionId: Int
    var artworkURL: String?
    var previewURL: String?
    var durationMillis: Int
    var genre: String
    var releaseDate: String
    var playedAt: Date

    init(
        trackId: Int,
        trackName: String,
        artistName: String,
        collectionName: String,
        collectionId: Int,
        artworkURL: String?,
        previewURL: String?,
        durationMillis: Int,
        genre: String,
        releaseDate: String,
        playedAt: Date = Date()
    ) {
        self.trackId = trackId
        self.trackName = trackName
        self.artistName = artistName
        self.collectionName = collectionName
        self.collectionId = collectionId
        self.artworkURL = artworkURL
        self.previewURL = previewURL
        self.durationMillis = durationMillis
        self.genre = genre
        self.releaseDate = releaseDate
        self.playedAt = playedAt
    }

    func toDomain() -> Song {
        Song(
            id: trackId,
            trackName: trackName,
            artistName: artistName,
            collectionName: collectionName,
            collectionId: collectionId,
            artworkURL: artworkURL.flatMap { URL(string: $0) },
            previewURL: previewURL.flatMap { URL(string: $0) },
            durationMillis: durationMillis,
            genre: genre,
            releaseDate: releaseDate
        )
    }

    func update(from song: Song) {
        self.trackId = song.id
        self.trackName = song.trackName
        self.artistName = song.artistName
        self.collectionName = song.collectionName
        self.collectionId = song.collectionId
        self.artworkURL = song.artworkURL?.absoluteString
        self.previewURL = song.previewURL?.absoluteString
        self.durationMillis = song.durationMillis
        self.genre = song.genre
        self.releaseDate = song.releaseDate
        self.playedAt = Date()
    }
}
