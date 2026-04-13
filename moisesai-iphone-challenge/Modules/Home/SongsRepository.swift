import CoreData

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

            guard let entities = try? context.fetch(request) else { return [] }
            return entities.map { $0.toDomain() }
        }
    }

    func getRecentlyPlayed() async -> [Song] {
        let context = persistenceController.viewContext
        return await context.perform {
            let request = RecentlyPlayedSongEntity.fetchRequest() as! NSFetchRequest<RecentlyPlayedSongEntity>
            request.sortDescriptors = [NSSortDescriptor(key: "playedAt", ascending: false)]
            request.fetchLimit = 20

            guard let entities = try? context.fetch(request) else { return [] }
            return entities.map { $0.toDomain() }
        }
    }

    func saveRecentlyPlayed(_ song: Song) async {
        let context = persistenceController.newBackgroundContext()
        await context.perform {
            let request = RecentlyPlayedSongEntity.fetchRequest() as! NSFetchRequest<RecentlyPlayedSongEntity>
            request.predicate = NSPredicate(format: "trackId == %lld", Int64(song.id))

            let entity: RecentlyPlayedSongEntity
            if let existing = try? context.fetch(request).first {
                entity = existing
            } else {
                entity = RecentlyPlayedSongEntity(context: context)
            }

            entity.update(from: song)
            try? context.save()
        }
    }

    // MARK: - Private

    private func cacheSongs(_ songs: [Song], for term: String) async {
        let context = persistenceController.newBackgroundContext()
        await context.perform {
            for song in songs {
                let request = CachedSongEntity.fetchRequest() as! NSFetchRequest<CachedSongEntity>
                request.predicate = NSPredicate(
                    format: "trackId == %lld AND searchTerm ==[c] %@",
                    Int64(song.id), term
                )

                let entity: CachedSongEntity
                if let existing = try? context.fetch(request).first {
                    entity = existing
                } else {
                    entity = CachedSongEntity(context: context)
                }

                entity.update(from: song, searchTerm: term)
            }
            try? context.save()
        }
    }
}
