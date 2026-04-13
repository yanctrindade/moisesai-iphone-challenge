# Architecture & Design Decisions

## 1. MVVM + Clean Architecture (UseCase + Repository)

**Decision:** Use MVVM with UseCases and Repository pattern instead of plain MVVM.

**Why:** Separating business logic (UseCases) from data coordination (Repository) keeps ViewModels thin and testable. Each UseCase has a single responsibility, making it easy to test in isolation. The Repository abstracts whether data comes from network or cache.

**Alternative considered:** Plain MVVM where ViewModel calls services directly. Rejected because it couples ViewModels to data sources and makes offline-first logic harder to test.

## 2. Action + ViewState Pattern

**Decision:** Each ViewModel defines its own `Action` enum and `ViewState` enum with a `send(_ action:)` method.

**Why:** Unidirectional data flow — Views send intents, ViewModels update state. No shared/global ViewState type means each screen's state is self-contained and doesn't leak concerns. Easy to test: send an action, assert the resulting state.

**Alternative considered:** Generic `ViewState<T>` shared across ViewModels. Rejected because different screens have different state needs (e.g., Player has `playing/paused/idle`, Home has `idle/loading/loaded/error`).

## 3. SwiftData over Core Data

**Decision:** Use SwiftData with `@Model` classes instead of Core Data with NSManagedObject.

**Why:** SwiftData is Apple's modern persistence framework, integrates natively with SwiftUI, requires less boilerplate (no `.xcdatamodeld`, no `NSPersistentContainer`, no `NSFetchRequest`). `@Model` classes are simpler than NSManagedObject subclasses.

**Alternative considered:** Core Data (initially implemented, then migrated). SwiftData was chosen to align with project requirements and modern Swift practices.

## 4. Protocol-Based Dependency Injection

**Decision:** Every layer depends on protocols, not concrete types. All dependencies injected via initializer.

**Why:** Enables testing with mocks at every boundary. Makes implementations swappable (e.g., `NetworkServiceProtocol` could be backed by URLSession, Alamofire, or a mock). Follows Dependency Inversion principle.

**Alternative considered:** Service locator pattern or singletons. Rejected because they hide dependencies and make testing harder.

## 5. Actor for ImageCache (not @unchecked Sendable)

**Decision:** Use Swift `actor` for `ImageCache` instead of marking it `@unchecked Sendable`.

**Why:** Actors provide compiler-verified thread safety. `@unchecked Sendable` bypasses the compiler check — it works but is a promise the developer makes without compiler enforcement. With `actor`, Swift guarantees no data races at compile time.

**Trade-off:** Actor requires `await` at call sites, adding slight overhead. Acceptable for image caching where the call is already async.

## 6. Shared AudioPlayerService Singleton

**Decision:** `AudioPlayerService` is a singleton with `private init`.

**Why:** Only one audio player should exist at a time. Without this, navigating Player → Album → Player created two instances playing simultaneously. The singleton ensures `play()` always stops the previous song first.

**Trade-off:** Singletons are harder to test and create global state. Mitigated by the protocol (`AudioPlayerServiceProtocol`) — tests inject a `MockAudioPlayerService` instead of the singleton.

## 7. Offline-First with Background Refresh

**Decision:** Show cached data immediately, fetch fresh data in background, update UI silently.

**Why:** Best user experience — no loading spinners when data exists in cache. The user sees content instantly on repeat searches or app relaunch. Loading state only appears on first-ever search with empty cache.

**Trade-off:** Cached data may be stale. Mitigated by always fetching fresh data in background and updating the UI when it arrives.

## 8. Per-View Strings Extensions (not centralized L10n)

**Decision:** Each view defines its own `Strings` enum via extension, containing only the localization keys it uses.

**Why:** Strings are co-located with the view that uses them. No cross-screen coupling. When reading a view file, all its strings are visible in the same file. Adding a new screen doesn't require editing a shared file.

**Alternative considered:** Centralized `L10n` enum (initially implemented, then refactored). Rejected because a single file grows large and creates merge conflicts when multiple features are developed in parallel.

## 9. DesignSystem with Named Tokens

**Decision:** Centralized `DesignSystem.swift` with `Typography`, `AppColors`, `Spacing`, `Sizing`, `Timing` enums.

**Why:** Single source of truth for all design values. No magic numbers scattered across views. Easy to update globally (e.g., changing player artwork size updates everywhere). Enables consistency across screens.

**Trade-off:** One more level of indirection. Mitigated by clear naming (e.g., `Sizing.playerArtwork` is self-documenting).

## 10. NavigationStack with RouterProtocol

**Decision:** Use `NavigationStack` with `NavigationPath`, a `Route` enum, and a `RouterProtocol` for all navigation.

**Why:** Type-safe navigation — every destination is a case in the `Route` enum with associated values. The `RouterProtocol` abstracts navigation so it can be mocked in tests. Views depend on the protocol via `@Environment`, not the concrete `Router` class.

**Alternative considered:** Full `Routable` protocol with `associatedtype` where each route defines its own destination view. Rejected for current scope — associated types require type erasure with `NavigationPath` and add complexity that doesn't pay off with 3 screens. Documented as future work if the app grows.

**Alternative considered:** Direct `.navigationDestination` without a router. Rejected because it scatters navigation logic across views and makes deep linking harder.

**Note on navigation ownership:** Currently views call `router.push()` directly (e.g., `router.push(.player(song:playlist:))`). An alternative is moving navigation into ViewModels via actions (e.g., `viewModel.send(.selectSong(song))` → ViewModel calls `router.push()`), which would make navigation testable via `MockRouter`. This was intentionally left in views for simplicity — navigation is a UI concern in this app, and moving it to ViewModels would require injecting the router into every ViewModel. If navigation logic grows complex (conditional routing, deep links, auth gates), moving it to ViewModels would be the right next step.

## 11. SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated

**Decision:** Set default actor isolation to `nonisolated` instead of Apple's new `MainActor` default.

**Why:** With `MainActor` default, every type (DTOs, services, repositories) is implicitly `@MainActor`, requiring `nonisolated` annotations everywhere. Most of our code (network, caching, business logic) runs off the main actor. Explicit `@MainActor` on ViewModels and Views is cleaner and more intentional.

**Trade-off:** Must remember to add `@MainActor` on ViewModels/Views. Mitigated by the consistent pattern documented in CLAUDE.md.

## 12. AppDependencies DI Container

**Decision:** A single `AppDependencies` struct holds all shared services (network, audio, cache, model container, network monitor). It's created once at app launch and passed through `SplashView → ContentView`. Views that need to construct ViewModels receive the deps and use factory methods.

**Why:** Previously, services and ViewModels were created ad-hoc inside `body` callbacks — `HomeViewModel` was re-created on every body re-evaluation and twice in navigation destinations. This wasted allocations and caused state loss on navigation. With a central container:
- `HomeViewModel` is hoisted into `@State` in `ContentView.init`, created once
- Services are created once at app launch and reused
- `AppDependencies.live(...)` factory for production
- Previews use the same factory with in-memory `ModelContainer` + fresh `NetworkMonitor`
- Future mocking: `AppDependencies(networkService: MockNetworkService(), ...)` for tests

**Alternative considered:** Individual `@Environment` values per service. Rejected because it scatters service discovery across views and requires injecting each service at the root.

**Alternative considered:** Singleton access pattern (`NetworkService.shared`). Rejected because it hides dependencies and breaks testability.

## 13. Seek Slider — Commit on Release

**Decision:** The player seek slider only calls `audioPlayer.seek()` on drag end, not during drag.

**Why:** Seeking AVPlayer on every frame during drag causes jitter and poor performance. During drag, only the visual time updates. On release, a single seek is committed with a 300ms debounce to prevent the time observer from snapping the slider back before AVPlayer catches up.

**Alternative considered:** Throttled seeking during drag. Rejected because even throttled seeks cause audible glitches in short preview tracks.
