import Foundation

struct iTunesSearchResponse: Decodable, Sendable {
    let resultCount: Int
    let results: [iTunesTrack]

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resultCount = try container.decode(Int.self, forKey: .resultCount)
        results = try container.decode([iTunesTrack].self, forKey: .results)
    }

    private enum CodingKeys: String, CodingKey {
        case resultCount, results
    }
}

struct iTunesTrack: Decodable, Sendable {
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let collectionName: String?
    let collectionId: Int?
    let artworkUrl100: String?
    let previewUrl: String?
    let trackTimeMillis: Int?
    let primaryGenreName: String?
    let releaseDate: String?
    let wrapperType: String?

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackId = try container.decodeIfPresent(Int.self, forKey: .trackId)
        trackName = try container.decodeIfPresent(String.self, forKey: .trackName)
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName)
        collectionName = try container.decodeIfPresent(String.self, forKey: .collectionName)
        collectionId = try container.decodeIfPresent(Int.self, forKey: .collectionId)
        artworkUrl100 = try container.decodeIfPresent(String.self, forKey: .artworkUrl100)
        previewUrl = try container.decodeIfPresent(String.self, forKey: .previewUrl)
        trackTimeMillis = try container.decodeIfPresent(Int.self, forKey: .trackTimeMillis)
        primaryGenreName = try container.decodeIfPresent(String.self, forKey: .primaryGenreName)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        wrapperType = try container.decodeIfPresent(String.self, forKey: .wrapperType)
    }

    private enum CodingKeys: String, CodingKey {
        case trackId, trackName, artistName, collectionName, collectionId
        case artworkUrl100, previewUrl, trackTimeMillis, primaryGenreName
        case releaseDate, wrapperType
    }
}
