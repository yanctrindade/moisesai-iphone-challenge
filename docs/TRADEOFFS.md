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

### Navigation Lives in Views, Not ViewModels
**What:** Views call `router.push()` directly. ViewModels don't know about navigation.

**Trade-off:** `MockRouter` exists but isn't used in tests because there's nothing to assert — ViewModels don't trigger navigation. Moving `router.push()` into ViewModels (via actions like `.selectSong`) would enable testing "did tapping a song navigate to the player?" but requires injecting the router into every ViewModel, adding coupling between ViewModels and navigation. For 3 screens with straightforward tap-to-navigate flows, keeping navigation in views is simpler. If the app adds conditional routing (auth gates, onboarding flows, deep links), moving navigation to ViewModels becomes worthwhile.

### RouterProtocol vs Routable Pattern
**What:** Navigation uses `RouterProtocol` with a concrete `Route` enum. Routes don't define their own destination views.

**Trade-off:** A `Routable` protocol with `associatedtype Body: View` where each route owns its destination would be more decoupled — adding a new screen wouldn't require editing `ContentView`'s `navigationDestination` switch. However, `associatedtype` doesn't work directly with `NavigationPath` (requires type erasure), and with only 3 destinations the switch statement is manageable. If the app grows beyond ~8 screens, migrating to `Routable` would be worthwhile.

### No Deep Linking
**What:** The app doesn't support opening specific songs or albums via URL schemes.

**Why:** Not in requirements. The `Route` enum and `Router` pattern are ready for deep linking if needed — just parse a URL into a `Route` and push it.

## Testing Offline Mode

**Don't use simulator airplane mode** — it can cause certificate/trust issues because the simulator shares the Mac's network stack and toggling airplane mode at that level interferes with TLS validation.

**Recommended approaches:**

1. **Debug force-offline toggle (built in)** — `NetworkMonitor.forceOffline = true` in debug builds, or set `UserDefaults.standard.set(true, forKey: "debug.forceOffline")` in the scheme's launch arguments. The monitor returns `isConnected: false` regardless of actual network state.

2. **Network Link Conditioner** — Xcode > Settings > Platforms > ...or Simulator > Features > Network Link Conditioner. Use "100% Loss" profile.

3. **Disable Wi-Fi on the host Mac** — cleanest way to simulate real offline state without certificate issues.

4. **Mock `NetworkMonitorProtocol` in tests** — inject a mock that returns `isConnected: false`.

## Future Work: Background Audio & Lock Screen Controls

**Why deferred:** Significant scope (2 new services, Info.plist config, iOS entitlements, lock screen testing) that would expand the challenge timeline. The current app stops playback when leaving the player screen — a deliberate choice to avoid partial background audio support.

### Architecture Sketch

1. **Info.plist** — Add `UIBackgroundModes: [audio]` to allow the app to continue playback when backgrounded.

2. **`NowPlayingInfoService`** — Wraps `MPNowPlayingInfoCenter.default()`. Provides `update(song:currentTime:duration:isPlaying:)` to populate lock screen with title, artist, album, artwork (fetched via `CachedAsyncImage`), duration. Clears info on stop.

3. **`RemoteCommandCenterService`** — Wraps `MPRemoteCommandCenter.shared()`. Configures play/pause, next/previous, and seek commands from lock screen/Control Center/AirPods. Closures call back into `PlayerViewModel`.

4. **`AudioPlayerService` changes** — `AVAudioSession` is already configured with `.playback` category; need to call `setActive(true)` when playback starts and ensure session remains active when app backgrounds.

5. **`PlayerView` change** — Remove `.onDisappear { send(.stop) }` so audio continues when user navigates away. Only stop when user explicitly pauses or playback ends.

6. **`PlayerViewModel` integration** — On song change, update NowPlayingInfo + RemoteCommand. Periodic time observer pushes updates to NowPlayingInfo (for scrubber sync).

Follows the same Provider-style pattern used elsewhere — protocols first, concrete implementations injected via DI.

## Future Work: API Search Improvements

Based on [Apple's iTunes Search API documentation](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/Searching.html), the following improvements could enhance search quality and reliability:

### Locale-Aware Search (`country` parameter)
**Current:** We don't send the `country` parameter — defaults to `US`.

**Improvement:** Use `Locale.current.region?.identifier` to automatically send the user's country code. This returns results from the local iTunes Store, showing regionally relevant content and pricing.

### Rate Limiting Protection
**Current:** No client-side throttling. Rapid searches could hit the ~20 calls/minute API limit.

**Improvement:** Implement a request queue with token bucket or sliding window rate limiter in `URLSessionNetworkService`. When the limit is approached, queue requests instead of dropping them. The 500ms search debounce helps but doesn't protect against pagination + search + album lookup happening simultaneously.

### Explicit Content Filter (`explicit` parameter)
**Current:** Defaults to `Yes` (explicit content included).

**Improvement:** Add a user setting to toggle explicit content filtering. Pass `explicit=No` in the `Endpoint` when the user opts out. Useful for family-friendly usage.

### Language Support (`lang` parameter)
**Current:** Not sent — defaults to `en_us`.

**Improvement:** Map the device's preferred language to the supported values (`en_us`, `ja_jp`). Limited impact since only English and Japanese are supported by the API.

### URL Encoding Validation
**Current:** `URLComponents` handles encoding automatically via `URLQueryItem`.

**Note:** Apple's docs emphasize encoding URLs correctly. Our implementation uses `URLQueryItem` which handles percent-encoding automatically. Spaces in search terms are properly encoded. No action needed, but worth verifying edge cases (special characters, emoji, CJK text).

### Response Caching Headers
**Current:** SwiftData provides our own cache layer. `URLSession` also has built-in HTTP cache via `URLCache`.

**Improvement:** Could configure `URLSessionConfiguration.urlCache` with a custom size to leverage HTTP-level caching as a second layer before SwiftData. This would reduce network calls for repeated identical requests within a session without hitting our SwiftData persistence layer.

### Search Attributes
**Current:** Generic search across all attributes.

**Improvement:** The API supports an `attribute` parameter to narrow search scope (e.g., `songTerm`, `artistTerm`, `albumTerm`). Could add search filters in the UI to let users search specifically by song name, artist, or album.

## Future Work: Observability, Analytics & Crash Reporting

All third-party integrations below would follow the **Provider design pattern** — a protocol defines the contract, a concrete provider implements it, and the app depends only on the protocol. This respects SOLID principles (Dependency Inversion, Open/Closed) and avoids hard coupling to any specific SDK.

### Observability / Logging Provider

**Current:** `os.Logger` for local debug logging. No remote observability.

**Improvement:** Define an `ObservabilityProviderProtocol` with methods like `log(level:message:metadata:)`, `trackPerformance(name:duration:)`, and `reportBreadcrumb(_:)`. Concrete implementations could wrap:
- **Datadog** — real-time log aggregation, APM traces, RUM (Real User Monitoring)
- **New Relic** — mobile performance monitoring
- **Sentry** — error tracking with breadcrumbs and performance spans
- **Custom backend** — forward logs to an internal observability stack

```swift
protocol ObservabilityProvider: Sendable {
    func log(_ level: LogLevel, message: String, metadata: [String: String])
    func startSpan(_ name: String) -> SpanToken
    func endSpan(_ token: SpanToken)
}

// Usage: inject via app container, no SDK imports in feature code
```

### Analytics Provider

**Current:** No analytics tracking.

**Improvement:** Define an `AnalyticsProviderProtocol` with `track(event:properties:)` and `identify(userId:traits:)`. Concrete implementations could wrap:
- **Firebase Analytics** — event tracking, user properties, funnels
- **Mixpanel** — behavioral analytics, cohort analysis
- **Amplitude** — product analytics, experimentation
- **Segment** — analytics router (sends to multiple providers)

Events to track:
- `search_performed(term:resultCount:)` — search behavior
- `song_played(trackId:source:)` — playback from home vs album
- `album_viewed(collectionId:)` — album engagement
- `share_tapped(trackId:)` — share feature usage
- `repeat_mode_changed(mode:)` — player feature adoption

```swift
protocol AnalyticsProvider: Sendable {
    func track(_ event: String, properties: [String: Any])
    func identify(userId: String, traits: [String: Any])
    func screen(_ name: String)
}
```

### Crash Reporting Provider

**Current:** No crash reporting. Crashes are only visible via Xcode organizer (requires TestFlight/App Store distribution).

**Improvement:** Define a `CrashReportingProviderProtocol` with `configure()`, `setUser(_:)`, and `recordError(_:)`. Concrete implementations could wrap:
- **Firebase Crashlytics** — real-time crash reporting, non-fatal error logging
- **Sentry** — crash reporting with breadcrumbs, release health
- **Datadog** — crash reporting integrated with RUM and logging

```swift
protocol CrashReportingProvider: Sendable {
    func configure()
    func setUser(_ userId: String)
    func recordNonFatal(_ error: Error, metadata: [String: String])
    func log(breadcrumb: String)
}
```

### Provider Composition

All providers would be registered in a central `AppServices` container injected at app launch:

```swift
struct AppServices {
    let analytics: AnalyticsProvider
    let observability: ObservabilityProvider
    let crashReporting: CrashReportingProvider
}

// In production:
let services = AppServices(
    analytics: FirebaseAnalyticsProvider(),
    observability: DatadogObservabilityProvider(),
    crashReporting: CrashlyticsProvider()
)

// In tests/previews:
let services = AppServices(
    analytics: NoOpAnalyticsProvider(),
    observability: NoOpObservabilityProvider(),
    crashReporting: NoOpCrashReportingProvider()
)
```

**Why the Provider pattern:**
- Feature code never imports Firebase, Datadog, or Sentry — only the protocol
- Swapping providers requires changing one line in the container, not every call site
- `NoOp` implementations for tests and previews — no SDK initialization overhead
- Multiple providers can be composed (e.g., log to both Datadog and local os.Logger)
- Follows Open/Closed principle — add new providers without modifying existing code
