# Moises AI - iPhone Challenge

A music player iOS app that searches songs via the Apple iTunes Search API, caches results with SwiftData for offline-first experience, and plays audio previews with AVFoundation.

## Requirements

- Xcode 26.1+
- iOS 26.1+
- Swift 6

## Getting Started

```bash
# Clone
git clone https://github.com/yanctrindade/moisesai-iphone-challenge.git
cd moisesai-iphone-challenge

# Open in Xcode
open moisesai-iphone-challenge.xcodeproj

# Or build from command line
xcodebuild -scheme moisesai-iphone-challenge -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild test -scheme moisesai-iphone-challenge -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:moisesai-iphone-challengeTests
```

## Architecture

**MVVM + Clean Architecture** with protocol-based dependency injection.

```
View → ViewModel → UseCase → Repository → Service (Network)
                                        → SwiftData (Cache)
```

| Layer | Responsibility |
|---|---|
| **View** | SwiftUI views, observes ViewModel state |
| **ViewModel** | `@Observable`, owns `Action` + `ViewState` enums, calls UseCases |
| **UseCase** | Single-responsibility business logic |
| **Repository** | Coordinates network + cache, offline-first strategy |
| **Service** | Protocol-based network abstraction (`NetworkServiceProtocol`) |

### ViewModel Pattern

Every ViewModel defines its own `Action` enum (user intents) and `ViewState` enum (screen state). Views call `viewModel.send(.action)` for all interactions.

### Offline-First

1. Show cached data immediately (no loading spinner if cache exists)
2. Fetch fresh data from API in background
3. Update UI silently when fresh data arrives
4. Loading state only when cache is empty

## Screens

| Screen | Description |
|---|---|
| **Splash** | Gradient background + app icon, 2s hold, fade to Home |
| **Home (Songs)** | Search bar with debounce, song list with pagination, recently played |
| **Player** | Album art (264pt), transport controls, seek slider, repeat modes, timeline |
| **Album** | Album header (120pt art), track listing from iTunes lookup API |
| **More Options** | Custom bottom sheet with View Album + Share |

## Tech Stack

| Technology | Usage |
|---|---|
| Swift 6 | Strict concurrency, async/await |
| SwiftUI | All UI, NavigationStack with typed NavigationPath |
| SwiftData | Offline caching (CachedSong, RecentlyPlayedSong) |
| AVFoundation | Audio playback (30s previews) |
| URLSession | Network layer with protocol abstraction |
| Apple Testing | Unit tests (`@Test`, `@Suite`, `#expect`) |
| swift-snapshot-testing | Visual regression tests |

## Project Structure

```
moisesai-iphone-challenge/
├── App/                          # App entry point, ContentView, navigation
├── Core/
│   ├── Network/                  # Endpoint, NetworkService, NetworkError
│   ├── Data/                     # SwiftData @Model classes (CachedSong, RecentlyPlayedSong)
│   ├── Domain/                   # Song model, iTunes DTOs
│   ├── Navigation/               # Router, Route enum
│   └── UI/Components/            # SongRowView, ErrorView, LoadingView, MarqueeText
├── Modules/
│   ├── Splash/                   # SplashView
│   ├── Home/                     # HomeView, HomeViewModel, UseCases, Repository
│   ├── Player/                   # PlayerView, PlayerViewModel, AudioPlayerService
│   ├── Album/                    # AlbumView, AlbumViewModel, FetchAlbumSongsUseCase
│   └── MoreOptions/              # MoreOptionsSheet
└── Resources/                    # Localizable.strings (en, pt-BR)

moisesai-iphone-challengeTests/
├── Fixtures/                     # SongFixture, iTunesTrackFixture
├── Mocks/                        # Mock protocols for all layers
├── Unit/                         # Unit tests by layer
│   ├── Network/
│   ├── Repositories/
│   ├── UseCases/
│   └── ViewModels/
└── Snapshot/                     # Visual regression tests
    ├── Components/
    └── Screens/
```

## Testing

### Unit Tests
- **61+ tests** across all layers: Network, Repository, UseCase, ViewModel
- Apple Testing framework (`import Testing`)
- Mock protocols for every dependency
- In-memory SwiftData for repository tests

### Snapshot Tests
- Visual regression for all screens and shared components
- Uses [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)

### Run Tests

```bash
# All tests
xcodebuild test -scheme moisesai-iphone-challenge \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:moisesai-iphone-challengeTests

# Record new snapshots (first run)
# Set isRecording = true in snapshot tests, run, then set back to false
```

## API

Uses the [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/Searching.html) (no auth required).

| Endpoint | Usage |
|---|---|
| `GET /search?term=...&media=music&entity=song` | Search songs |
| `GET /lookup?id={collectionId}&entity=song` | Album tracks |

## Localization

Supported languages:
- English (en)
- Brazilian Portuguese (pt-BR)

All user-facing strings use `NSLocalizedString` with keys in `Localizable.strings`.

## Accessibility

- VoiceOver labels on all interactive elements
- Accessibility traits (`.isButton`, `.isHeader`)
- Localized accessibility values (repeat mode states)

## Key Design Decisions

- **`SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`** — `@MainActor` applied explicitly only on ViewModels/Views, keeping DTOs and services clean
- **Seek slider debounce** — only commits to AVPlayer on drag end (300ms guard) to prevent jitter
- **MarqueeText** — scrolling text for long album titles in player navbar
- **Custom MoreOptionsSheet** — matches Figma spec (#262626 at 80% opacity + blur)
- **AppDependencies** — DI container with live factory, created once at app launch, hoists ViewModels into `@State` to prevent re-creation on body re-evaluation
- **RouterProtocol** — navigation abstracted behind protocol for testability (MockRouter in tests)
- **Actor-based ImageCache** — compiler-verified thread safety, no `@unchecked Sendable`
- **Provider pattern** — planned for observability (Datadog), analytics, and crash reporting

## Documentation

- [docs/DECISIONS.md](docs/DECISIONS.md) — 12 architecture decisions with reasoning and alternatives considered
- [docs/TRADEOFFS.md](docs/TRADEOFFS.md) — known limitations, performance trade-offs, scope decisions, and future work (API improvements, observability, analytics, crash reporting)
