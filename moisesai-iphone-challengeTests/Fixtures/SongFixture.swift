import Foundation
@testable import moisesai_iphone_challenge

enum SongFixture {
    static func make(
        id: Int = 1,
        trackName: String = "Get Lucky",
        artistName: String = "Daft Punk feat. Pharrell Williams",
        collectionName: String = "Random Access Memories",
        collectionId: Int = 100,
        artworkURL: URL? = URL(string: "https://example.com/artwork100x100.jpg"),
        previewURL: URL? = URL(string: "https://example.com/preview.m4a"),
        durationMillis: Int = 248000,
        genre: String = "Electronic",
        releaseDate: String = "2013-05-17T07:00:00Z"
    ) -> Song {
        Song(
            id: id,
            trackName: trackName,
            artistName: artistName,
            collectionName: collectionName,
            collectionId: collectionId,
            artworkURL: artworkURL,
            previewURL: previewURL,
            durationMillis: durationMillis,
            genre: genre,
            releaseDate: releaseDate
        )
    }

    static func makeList(count: Int = 5) -> [Song] {
        (0..<count).map { index in
            make(
                id: index + 1,
                trackName: "Song \(index + 1)",
                artistName: "Artist \(index + 1)",
                collectionName: "Album \(index + 1)",
                collectionId: 100 + index
            )
        }
    }
}

enum iTunesTrackFixture {
    static func make(
        trackId: Int? = 1,
        trackName: String? = "Get Lucky",
        artistName: String? = "Daft Punk feat. Pharrell Williams",
        collectionName: String? = "Random Access Memories",
        collectionId: Int? = 100,
        artworkUrl100: String? = "https://example.com/artwork100x100.jpg",
        previewUrl: String? = "https://example.com/preview.m4a",
        trackTimeMillis: Int? = 248000,
        primaryGenreName: String? = "Electronic",
        releaseDate: String? = "2013-05-17T07:00:00Z",
        wrapperType: String? = "track"
    ) -> iTunesTrack {
        iTunesTrack(
            trackId: trackId,
            trackName: trackName,
            artistName: artistName,
            collectionName: collectionName,
            collectionId: collectionId,
            artworkUrl100: artworkUrl100,
            previewUrl: previewUrl,
            trackTimeMillis: trackTimeMillis,
            primaryGenreName: primaryGenreName,
            releaseDate: releaseDate,
            wrapperType: wrapperType
        )
    }
}

enum iTunesSearchResponseFixture {
    static func make(
        resultCount: Int? = nil,
        results: [iTunesTrack]? = nil
    ) -> iTunesSearchResponse {
        let tracks = results ?? [iTunesTrackFixture.make()]
        return iTunesSearchResponse(
            resultCount: resultCount ?? tracks.count,
            results: tracks
        )
    }

    static func makeJSON(tracks: [iTunesTrack]? = nil) -> Data {
        let response = make(results: tracks)
        let dict: [String: Any] = [
            "resultCount": response.resultCount,
            "results": response.results.map { track in
                var obj: [String: Any] = [:]
                if let v = track.trackId { obj["trackId"] = v }
                if let v = track.trackName { obj["trackName"] = v }
                if let v = track.artistName { obj["artistName"] = v }
                if let v = track.collectionName { obj["collectionName"] = v }
                if let v = track.collectionId { obj["collectionId"] = v }
                if let v = track.artworkUrl100 { obj["artworkUrl100"] = v }
                if let v = track.previewUrl { obj["previewUrl"] = v }
                if let v = track.trackTimeMillis { obj["trackTimeMillis"] = v }
                if let v = track.primaryGenreName { obj["primaryGenreName"] = v }
                if let v = track.releaseDate { obj["releaseDate"] = v }
                if let v = track.wrapperType { obj["wrapperType"] = v }
                return obj
            }
        ]
        return try! JSONSerialization.data(withJSONObject: dict)
    }
}
