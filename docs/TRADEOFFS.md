# Trade-offs & Known Limitations

## Architecture Trade-offs

### UseCase Layer Adds Indirection
**What:** Some UseCases (e.g., `GetRecentlyPlayedUseCase`) are thin wrappers that just forward to the repository.

**Why we kept them:** Consistency — every ViewModel depends on UseCases, not repositories. If business logic is needed later (e.g., filtering, sorting, combining data sources), the UseCase is already in place. Removing the layer for "simple" cases creates inconsistency and makes the architecture harder to follow.

**Cost:** Extra files and one more protocol to mock in tests.

### Repository as Shared Infrastructure
**What:** `SongsRepository` lives in `Core/Repositories/`, shared between Home and Player modules.

**Trade-off:** If the repository grows too large, it may need splitting into `SearchRepository` and `PlaybackRepository`. For now, a single repository keeps things simple and avoids duplicating SwiftData model access logic.

### ViewModel Creates Tasks Internally
**What:** ViewModels create `Task {}` blocks inside `send()` to run async work.

**Trade-off:** Makes testing async behavior require `Task.sleep` delays. A more testable approach would be to make `send()` async or use a task scheduler. Current approach was chosen for simplicity and matches SwiftUI's fire-and-forget pattern.

## Performance Trade-offs

### CachedAsyncImage Actor Overhead
**What:** ImageCache is an `actor`, requiring `await` for every get/set.

**Trade-off:** Slight overhead from actor hop vs `@unchecked Sendable` which would be synchronous. Chosen because compiler-verified thread safety is worth the minor performance cost for image caching (already async by nature).

### In-Memory Image Cache Only
**What:** `ImageCache` uses `NSCache` (memory only). Images are re-downloaded after app termination.

**Why not disk cache:** Keeps complexity low. `AsyncImage` already handles HTTP caching via `URLCache`. Our `NSCache` layer prevents redundant decoding during scroll, which is the main performance bottleneck. A disk cache would add file I/O complexity for marginal benefit on preview-sized images.

### SwiftData on Main Context
**What:** Some SwiftData reads happen on the main context via `ModelContext(modelContainer)`.

**Trade-off:** Heavy queries could block the main thread. Mitigated by the fact that our datasets are small (20 songs per page, 20 recently played max) and SwiftData queries are fast. For larger datasets, background `ModelActor` would be needed.

## UI/UX Trade-offs

### 30-Second Preview Limitation
**What:** iTunes API only provides 30-second AAC previews, not full songs.

**Impact:** The seek slider and timeline reflect a 30-second track. Forward/backward navigation feels abrupt on short tracks. This is an API limitation, not an architectural one.

### Debounced Search (500ms)
**What:** Search waits 500ms after the user stops typing before making an API request.

**Trade-off:** Reduces API calls and prevents rate limiting (20 calls/minute), but adds perceived latency. Users typing slowly may notice the delay. Cached results show instantly while fresh data loads in background, mitigating this.

### No Background Audio
**What:** Audio stops when leaving the player screen (`.onDisappear` calls `.stop`).

**Why:** The assignment focuses on preview playback within the player screen, not background audio. Supporting background audio would require `AVAudioSession` category configuration, `MPNowPlayingInfoCenter`, and remote command center setup — significant scope increase for 30-second previews.

### MarqueeText for Long Titles
**What:** Long album titles in the player navbar scroll horizontally.

**Trade-off:** The `textWidth` measurement uses `UIFont.systemFont` hardcoded at 16px semibold, which may not perfectly match the actual rendered font if the system font changes. For short titles, it renders as plain `Text` with no animation overhead.

## Testing Trade-offs

### Async Test Timing with Task.sleep
**What:** ViewModel tests use `try await Task.sleep(for: .seconds(1))` to wait for debounced search.

**Trade-off:** Makes tests slower and potentially flaky under heavy load. A test scheduler or dependency-injected clock would be more reliable but adds significant complexity for this project scope.

### Snapshot Tests on Single Device
**What:** Snapshots are recorded on iPhone 17 Pro only.

**Trade-off:** Doesn't catch layout issues on smaller devices (iPhone SE) or larger ones (Pro Max). Adding multiple device sizes would multiply the number of reference images. For this project scope, single-device coverage is sufficient.

### MockURLProtocol Shared State
**What:** `MockURLProtocol.requestHandler` is a static property shared across tests.

**Trade-off:** Tests must be serialized (`.serialized` on the suite) to prevent races. An alternative would be per-test URLSession configurations, but `URLProtocol` registration is process-global by design.

## Scope Decisions

### No Favorites Feature
**What:** The More Options sheet has View Album and Share but no Favorites toggle.

**Why:** Not in the Figma design specs. The data model could support it (add a `isFavorite` field to SwiftData), but implementing UI + persistence for an unspecified feature would be speculative.

### No Background Data Sync
**What:** Data is only fetched when the user actively searches or navigates.

**Why:** The iTunes Search API is read-only with rate limits. There's no user-specific data to sync. Background fetch would only pre-cache popular queries, which adds complexity without clear user benefit.

### No Deep Linking
**What:** The app doesn't support opening specific songs or albums via URL schemes.

**Why:** Not in requirements. The `Route` enum and `Router` pattern are ready for deep linking if needed — just parse a URL into a `Route` and push it.
