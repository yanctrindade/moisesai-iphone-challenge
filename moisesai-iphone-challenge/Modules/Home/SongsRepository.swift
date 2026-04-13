import CoreData
import os

private let logger = Logger(subsystem: "com.yantrindade.moisesai", category: "SongsRepository")

final class SongsRepository: SongsRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let persistenceController: PersistenceController

    init(
        networkService: NetworkServiceProtocol,
        persistenceController: PersistenceController = .shared
    ) {
        self.networkService = networkService
        self.persistenceController = persistenceController
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
        let context = persistenceController.viewContext
        return await context.perform {
            let request = CachedSongEntity.fetchRequest() as! NSFetchRequest<CachedSongEntity>
            request.predicate = NSPredicate(format: "searchTerm ==[c] %@", term)
            request.sortDescriptors = [NSSortDescriptor(key: "cachedAt", ascending: true)]

            do {
                let entities = try context.fetch(request)
                return entities.map { $0.toDomain() }
            } catch {
                logger.error("Failed to fetch cached songs: \(error.localizedDescription)")
                return []
            }
        }
    }

    func getRecentlyPlayed() async -> [Song] {
        let context = persistenceController.viewContext
        return await context.perform {
            let request = RecentlyPlayedSongEntity.fetchRequest() as! NSFetchRequest<RecentlyPlayedSongEntity>
            request.sortDescriptors = [NSSortDescriptor(key: "playedAt", ascending: false)]
            request.fetchLimit = 20

            do {
                let entities = try context.fetch(request)
                return entities.map { $0.toDomain() }
            } catch {
                logger.error("Failed to fetch recently played: \(error.localizedDescription)")
                return []
            }
        }
    }

    func saveRecentlyPlayed(_ song: Song) async {
        let context = persistenceController.newBackgroundContext()
        await context.perform {
            let request = RecentlyPlayedSongEntity.fetchRequest() as! NSFetchRequest<RecentlyPlayedSongEntity>
            request.predicate = NSPredicate(format: "trackId == %lld", Int64(song.id))

            do {
                let entity = try context.fetch(request).first ?? RecentlyPlayedSongEntity(context: context)
                entity.update(from: song)
                try context.save()
            } catch {
                logger.error("Failed to save recently played: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    private func cacheSongs(_ songs: [Song], for term: String) async {
        guard !songs.isEmpty else { return }

        let context = persistenceController.newBackgroundContext()
        await context.perform {
            let trackIds = songs.map { Int64($0.id) }
            let request = CachedSongEntity.fetchRequest() as! NSFetchRequest<CachedSongEntity>
            request.predicate = NSPredicate(
                format: "searchTerm ==[c] %@ AND trackId IN %@",
                term,
                trackIds as [NSNumber]
            )

            do {
                let existingEntities = try context.fetch(request)
                let existingByTrackId = Dictionary(
                    uniqueKeysWithValues: existingEntities.map { ($0.trackId, $0) }
                )

                for song in songs {
                    let entity = existingByTrackId[Int64(song.id)] ?? CachedSongEntity(context: context)
                    entity.update(from: song, searchTerm: term)
                }

                try context.save()
            } catch {
                logger.error("Failed to cache songs: \(error.localizedDescription)")
            }
        }
    }
}
