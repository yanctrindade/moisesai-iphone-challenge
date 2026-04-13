# Moises AI iPhone Challenge

Music player iOS app — searches songs via Apple iTunes API, caches with Core Data, plays audio previews with AVFoundation.

## Tech Stack

- **Language:** Swift 6 (strict concurrency checking enabled)
- **UI:** SwiftUI (iOS 18+)
- **Architecture:** MVVM + Clean Architecture layers
- **Persistence:** Core Data (offline-first)
- **Networking:** URLSession with protocol-based abstraction
- **Audio:** AVFoundation / AVPlayer
- **Testing:** Apple Testing framework + swift-snapshot-testing
- **Xcode:** 26.1

## Architecture

```
View → ViewModel → UseCase → Repository → Service (Network)
                                        → Core Data (Cache)
```

### View (SwiftUI)
- Pure UI — no business logic, no direct network/data calls
- Observes ViewModel state via `@Observable`
- Switches on ViewModel's `ViewState` enum for rendering

### ViewModel (`@Observable`, `@MainActor`)
- Defines its own `Action` enum (user intents) and `ViewState` enum (screen state)
- Exposes a `send(_ action:)` method — Views call this for all interactions
- Handles state transitions (loading → loaded/error)
- Never imports UIKit or network types

### UseCase
- Single-responsibility interactors (e.g., `SearchSongsUseCase`, `PlaySongUseCase`)
- Pure business logic — receives a Repository protocol, returns domain models
- Stateless where possible

### Repository (Protocol-based)
- Coordinates between Service (network) and Core Data (cache)
- **Offline-first strategy:**
  1. Show cached data immediately (no loading spinner if cache exists)
  2. Fetch fresh data from API in background
  3. Update UI silently when fresh data arrives
  4. Loading state only shown when cache is empty (e.g., first-ever launch)
- Maps between network DTOs, Core Data entities, and domain models
- Protocol-defined so implementations are swappable

### Service (Network Abstraction)
- `NetworkServiceProtocol` — the API implementation is replaceable without affecting other layers
- Concrete implementation uses URLSession
- Endpoint definition via enum/struct (path, HTTP method, query params, headers)
- Pagination built into request/response models
- All response types are `Decodable` and `Sendable`

## Navigation

- `NavigationStack` with typed `NavigationPath`
- Router/Coordinator pattern — a `Router` class defines all destinations
- Views navigate by pushing route values onto the path, not by embedding destination views

## Swift 6 & Concurrency

- Strict concurrency checking enabled in build settings
- `async/await` for all asynchronous work
- `@MainActor` on ViewModels and Views
- `Sendable` conformance on all data/domain models
- Use `TaskGroup` for parallel fetches where appropriate
- Cancel tasks in ViewModel `deinit` or `.onDisappear`

## Core Data (Persistence)

- `NSPersistentContainer` wrapped in a `PersistenceController`
- Use `NSManagedObject` subclasses for entities (`CachedSong`, `RecentlyPlayedSong`)
- Write operations on background context (`newBackgroundContext()`)
- Read operations via fetch requests through the repository layer
- In-memory store option for previews and tests (`NSInMemoryStoreType`)
- Recently played songs tracked with timestamps, displayed on home screen

## Networking (iTunes Search API)

- **Base URL:** `https://itunes.apple.com/search`
- **Key params:** `term`, `media=music`, `entity=song`, `limit` (1-200), `offset`
- **Response:** `{ resultCount: Int, results: [Track] }`
- **Rate limit:** ~20 calls/minute
- `NetworkServiceProtocol` with methods like `func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T`
- `Endpoint` type defines: base URL, path, HTTP method, query parameters, headers
- Error types: `NetworkError` enum (badURL, unauthorized, serverError, decodingFailed, noConnection, etc.)
- Mock-friendly: inject `URLProtocol` subclass for testing

## Design System

- **Splash background:** `Base/Gradient/Spotlight` — `linear-gradient(39.45deg, #000000 33.57%, #0086A0 205.11%)`
- **All other screens background:** `#000000` (pure black)
- **Text primary:** `.primary` (white in dark mode)
- **Text secondary:** `.secondary` (gray in dark mode)
- **Accent/Tint:** `.tint` / `.accentColor` (system default)
- **Icons:** SF Symbols
- **Typography:** System font (SF Pro) as default, architecture ready to swap in Articulat CF later
  - Song/track row title: 16px, medium (500), line-height 120%
  - Song/track row subtitle: 12px, medium (500), line-height 140%
  - Player song title: 32px, semibold (600), line-height 120%
  - Player artist name: 16px, medium (500), line-height 120%
- **App appearance:** Force dark mode (`.preferredColorScheme(.dark)`)

## Project Structure

```
/ (repo root)
├── moisesai-iphone-challenge.xcodeproj/
├── moisesai-iphone-challenge/           (main app target)
│   ├── App/
│   │   ├── moisesai_iphone_challengeApp.swift
│   │   └── ContentView.swift
│   ├── Core/
│   │   ├── Network/
│   │   ├── Data/
│   │   ├── Domain/
│   │   ├── Navigation/
│   │   └── UI/Components/
│   └── Modules/
│       ├── Splash/
│       ├── Home/
│       ├── Player/
│       ├── Album/
│       └── MoreOptions/
├── moisesai-iphone-challengeTests/
├── moisesai-iphone-challengeUITests/
├── docs/
│   ├── specs/       (screen screenshots)
│   ├── appicon/     (app icon source)
│   └── plans/       (versioned plans)
├── CLAUDE.md
└── .gitignore
```

## ViewModel Pattern: Action + ViewState

Each ViewModel defines its own `Action` enum and `ViewState` enum. No shared/global ViewState type.

```swift
@Observable @MainActor
final class HomeViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded([Song])
        case error(String)
    }

    enum Action {
        case search(String)
        case loadMore
        case refresh
        case selectSong(Song)
    }

    private(set) var state: ViewState = .idle

    func send(_ action: Action) {
        switch action {
        case .search(let term):
            Task { await performSearch(term) }
        // ...
        }
    }
}
```

Views call `viewModel.send(.action)` for all interactions. Views switch on `viewModel.state` for rendering.

## Screens

### Splash
- Background: `Base/Gradient/Spotlight` gradient
- Centered music note icon (100x100pt)
- 2 second hold, fade transition to Home

### Home (Songs)
- Top bar: search icon (`magnifyingglass`, left) + "Songs" title (center)
- Song rows: album art (~50pt) | title + artist | `...` button
- No row separators
- First launch: empty list + search prompt
- Subsequent: show cached results immediately
- Infinite scroll pagination, pull-to-refresh
- Tap row → Player, tap `...` → More Options sheet

### Player
- Nav: back chevron | album title (center) | `...`
- Album artwork: 264x264pt, rounded corners
- Song title: 32px semibold, artist: 16px medium
- Repeat toggle icon
- Timeline slider with current/remaining time
- Transport: rewind | play/pause (large) | forward
- Tapping album title → Album screen

### Album
- Nav: back chevron, no title
- Header: album art (~120pt) + album title + artist
- Track rows: small art (~44pt) | title (16px) + artist (12px)
- No `...` buttons, no separators
- Tap track → Player

### More Options (Bottom Sheet)
- `.presentationDetents([.medium])`
- Song info header + options: View Album, Share, Favorites toggle

## Schemes & Build Configurations

| | **Staging** | **App Store** |
|---|---|---|
| **Scheme** | `moisesai-iphone-challenge-staging` | `moisesai-iphone-challenge` |
| **Bundle ID** | `...moisesai-iphone-challenge.staging` | `...moisesai-iphone-challenge` |
| **Display Name** | `Moises (Staging)` | `Moises` |
| **App Icon** | Staging icon (badge overlay) | Production icon |
| **Logging** | Verbose (`.debug`) | Minimal (`.error` only) |

- `.xcconfig` files: `Staging.xcconfig`, `Production.xcconfig`
- `Environment.swift` reads config from Info.plist/build settings

## Testing

### Unit Tests (Apple Testing framework)
- `import Testing` — use `@Test`, `@Suite`, `#expect`, `#require`
- Naming: `test_methodName_condition_expectedResult`

### Required Coverage
- **Service tests:** mock URLProtocol
- **Repository tests:** mock Service + in-memory Core Data
- **UseCase tests:** mock Repository
- **ViewModel tests:** mock UseCase, verify state transitions

### Snapshot Tests (swift-snapshot-testing)
- Components: song row, player controls, loading/error states
- Screens: home, player, album (populated, empty, error)
- Variants: iPhone SE + iPhone 17 Pro, light + dark mode

### Mocking Strategy
- Every protocol gets a `Mock` counterpart in `Tests/Mocks/`

## Code Style

- No force unwraps (`!`) — use `guard let` or `if let`
- `guard` for early returns
- Extensions in separate files when non-trivial
- Prefer value types (`struct`) for models
- Accessibility: `.accessibilityLabel` and `.accessibilityHint` on interactive elements
- No `print()` — use `os.Logger`

## Build & Run

```bash
# Build
xcodebuild -scheme moisesai-iphone-challenge -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Test
xcodebuild -scheme moisesai-iphone-challenge -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Dependencies

- **swift-snapshot-testing** (PointFree) — snapshot/visual regression tests
- No other third-party dependencies — use Apple frameworks only
