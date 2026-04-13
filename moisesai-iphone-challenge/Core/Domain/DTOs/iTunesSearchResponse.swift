import Foundation

struct iTunesSearchResponse: Decodable, Sendable {
    let resultCount: Int
    let results: [iTunesTrack]
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
}
