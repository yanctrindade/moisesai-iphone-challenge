import Foundation

protocol SongsRepositoryProtocol: Sendable {
    func searchSongs(term: String, limit: Int, offset: Int) async throws -> [Song]
    func getCachedSongs(for term: String) async -> [Song]
    func getRecentlyPlayed() async -> [Song]
    func saveRecentlyPlayed(_ song: Song) async
}
