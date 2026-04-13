import Foundation

enum Route: Hashable {
    case home
    case player(song: Song, playlist: [Song])
    case album(collectionId: Int, collectionName: String, artworkURL: URL?)
}
