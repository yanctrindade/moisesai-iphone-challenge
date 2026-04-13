import Foundation
import SwiftData
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "SongsRepository")

final class SongsRepository: SongsRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let modelContainer: ModelContainer

    init(
        networkService: NetworkServiceProtocol,
        modelContainer: ModelContainer
    ) {
        self.networkService = networkService
        self.modelContainer = modelContainer
    }

    func searchSongs(term: String, limit: Int, offset: Int) async throws -> [Song] {
        let endpoint = Endpoint.searchSongs(term: term, limit: limit, offset: offset)
        let response: iTunesSearchResponse = try await networkService.request(endpoint)

        let songs = response.results
            .filter { $0.wrapperType == "track" }
            .map { Song(from: $0) }

        await cacheSongs(songs, for: term)

        return songs
    }

    func getCachedSongs(for term: String) async -> [Song] {
        let context = ModelContext(modelContainer)
        let lowercasedTerm = term.lowercased()

        do {
            let descriptor = FetchDescriptor<CachedSong>(
                predicate: #Predicate { $0.searchTerm.localizedStandardContains(lowercasedTerm) },
                sortBy: [SortDescriptor(\.cachedAt)]
            )
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            logger.error("Failed to fetch cached songs: \(error.localizedDescription)")
            return []
        }
    }

    func getRecentlyPlayed() async -> [Song] {
        let context = ModelContext(modelContainer)

        do {
            var descriptor = FetchDescriptor<RecentlyPlayedSong>(
                sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
            )
            descriptor.fetchLimit = 20
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            logger.error("Failed to fetch recently played: \(error.localizedDescription)")
            return []
        }
    }

    func saveRecentlyPlayed(_ song: Song) async {
        let context = ModelContext(modelContainer)
        let songId = song.id

        do {
            let descriptor = FetchDescriptor<RecentlyPlayedSong>(
                predicate: #Predicate { $0.trackId == songId }
            )

            if let existing = try context.fetch(descriptor).first {
                existing.update(from: song)
            } else {
                let entity = RecentlyPlayedSong(
                    trackId: song.id,
                    trackName: song.trackName,
                    artistName: song.artistName,
                    collectionName: song.collectionName,
                    collectionId: song.collectionId,
                    artworkURL: song.artworkURL?.absoluteString,
                    previewURL: song.previewURL?.absoluteString,
                    durationMillis: song.durationMillis,
                    genre: song.genre,
                    releaseDate: song.releaseDate
                )
                context.insert(entity)
            }
            try context.save()
        } catch {
            logger.error("Failed to save recently played: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func cacheSongs(_ songs: [Song], for term: String) async {
        guard !songs.isEmpty else { return }

        let context = ModelContext(modelContainer)
        let trackIds = songs.map { $0.id }
        let lowercasedTerm = term.lowercased()

        do {
            let descriptor = FetchDescriptor<CachedSong>(
                predicate: #Predicate { trackIds.contains($0.trackId) && $0.searchTerm.localizedStandardContains(lowercasedTerm) }
            )

            let existing = try context.fetch(descriptor)
            let existingByTrackId = Dictionary(uniqueKeysWithValues: existing.map { ($0.trackId, $0) })

            for song in songs {
                if let entity = existingByTrackId[song.id] {
                    entity.update(from: song, searchTerm: term)
                } else {
                    let entity = CachedSong(
                        trackId: song.id,
                        trackName: song.trackName,
                        artistName: song.artistName,
                        collectionName: song.collectionName,
                        collectionId: song.collectionId,
                        artworkURL: song.artworkURL?.absoluteString,
                        previewURL: song.previewURL?.absoluteString,
                        durationMillis: song.durationMillis,
                        genre: song.genre,
                        releaseDate: song.releaseDate,
                        searchTerm: term
                    )
                    context.insert(entity)
                }
            }
            try context.save()
        } catch {
            logger.error("Failed to cache songs: \(error.localizedDescription)")
        }
    }
}
