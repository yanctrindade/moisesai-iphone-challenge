import CoreData

@objc(RecentlyPlayedSongEntity)
final class RecentlyPlayedSongEntity: NSManagedObject {
    @NSManaged var trackId: Int64
    @NSManaged var trackName: String
    @NSManaged var artistName: String
    @NSManaged var collectionName: String?
    @NSManaged var collectionId: Int64
    @NSManaged var artworkURL: String?
    @NSManaged var previewURL: String?
    @NSManaged var durationMillis: Int64
    @NSManaged var genre: String?
    @NSManaged var releaseDate: String?
    @NSManaged var playedAt: Date?
}

extension RecentlyPlayedSongEntity {
    func toDomain() -> Song {
        Song(
            id: Int(trackId),
            trackName: trackName,
            artistName: artistName,
            collectionName: collectionName ?? "Unknown",
            collectionId: Int(collectionId),
            artworkURL: artworkURL.flatMap { URL(string: $0) },
            previewURL: previewURL.flatMap { URL(string: $0) },
            durationMillis: Int(durationMillis),
            genre: genre ?? "Unknown",
            releaseDate: releaseDate ?? ""
        )
    }

    func update(from song: Song) {
        self.trackId = Int64(song.id)
        self.trackName = song.trackName
        self.artistName = song.artistName
        self.collectionName = song.collectionName
        self.collectionId = Int64(song.collectionId)
        self.artworkURL = song.artworkURL?.absoluteString
        self.previewURL = song.previewURL?.absoluteString
        self.durationMillis = Int64(song.durationMillis)
        self.genre = song.genre
        self.releaseDate = song.releaseDate
        self.playedAt = Date()
    }
}
