# Moises AI iPhone Challenge

Music player iOS app — fetches songs from an API, caches with Core Data, plays audio with AVFoundation.

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
- Uses `ViewState<T>` enum for loading/loaded/error rendering

### ViewModel (`@Observable`, `@MainActor`)
- Owns UseCase instances, calls them on user actions
- Exposes state as published properties
- Handles state transitions (loading → loaded/error)
- Never imports UIKit or network types

### UseCase
- Single-responsibility interactors (e.g., `FetchSongsUseCase`, `PlaySongUseCase`)
- Pure business logic — receives a Repository protocol, returns domain models
- Stateless where possible

### Repository (Protocol-based)
- Coordinates between Service (network) and Core Data (cache)
- **Offline-first strategy:** load cached data first, then refresh from network in background
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
- Router/Coordinator pattern — a `Router` class (or enum) defines all destinations
- Views navigate by pushing route values onto the path, not by embedding destination views
- Conforms to path-based navigation protocol

## Swift 6 & Concurrency

- Strict concurrency checking enabled in build settings
- `async/await` for all asynchronous work
- `@MainActor` on ViewModels and Views
- `Sendable` conformance on all data/domain models
- Use `TaskGroup` for parallel fetches where appropriate
- Cancel tasks in ViewModel `deinit` or `.onDisappear`

## Core Data (Persistence)

- `NSPersistentContainer` wrapped in a `PersistenceController`
- Use `NSManagedObject` subclasses for entities (songs, recently played)
- Write operations on background context (`newBackgroundContext()`)
- Read operations via fetch requests through the repository layer
- In-memory store option for previews and tests (`NSInMemoryStoreType`)
- Recently played songs tracked with timestamps, displayed on home screen

## Networking

- `NetworkServiceProtocol` with methods like `func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T`
- `Endpoint` type defines: base URL, path, HTTP method, query parameters, headers
- Pagination: `PaginatedResponse<T>` wrapper with `items`, `page`, `totalPages` (or cursor-based)
- Error types: `NetworkError` enum (badURL, unauthorized, serverError, decodingFailed, noConnection, etc.)
- Mock-friendly: inject `URLProtocol` subclass for testing

## Project Structure

```
moisesai-iphone-challenge/
├── App/
│   ├── moisesai_iphone_challengeApp.swift
│   └── ContentView.swift
├── Core/
│   ├── Network/
│   │   ├── NetworkServiceProtocol.swift
│   │   ├── URLSessionNetworkService.swift
│   │   ├── Endpoint.swift
│   │   ├── NetworkError.swift
│   │   └── PaginatedResponse.swift
│   ├── Data/
│   │   ├── PersistenceController.swift
│   │   ├── MoisesAI.xcdatamodeld
│   │   └── Entities/
│   ├── Navigation/
│   │   ├── Router.swift
│   │   └── Route.swift
│   └── Models/
│       └── (Domain models)
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   ├── FetchSongsUseCase.swift
│   │   └── SongsRepository.swift
│   └── Player/
│       ├── PlayerView.swift
│       ├── PlayerViewModel.swift
│       └── Components/
└── Tests/
    ├── Unit/
    │   ├── Services/
    │   ├── Repositories/
    │   ├── UseCases/
    │   └── ViewModels/
    ├── Snapshot/
    │   ├── Components/
    │   └── Screens/
    └── Mocks/
```

## Testing

### Unit Tests (Apple Testing framework)
- `import Testing` — use `@Test`, `@Suite`, `#expect`, `#require`
- Naming: `test_methodName_condition_expectedResult`
- All tests are `async throws` by default

### Required Coverage

**Service tests:** Mock `URLProtocol` to verify request construction, response parsing, error mapping, and pagination handling.

**Repository tests:** Mock Service protocol + in-memory Core Data stack (`NSPersistentContainer` with `NSInMemoryStoreType`). Verify offline-first logic, cache reads/writes, DTO-to-domain mapping, and network fallback.

**UseCase tests:** Mock Repository protocol. Verify business logic, data transformations, edge cases (empty results, errors).

**ViewModel tests:** Mock UseCase protocol. Verify state transitions (`ViewState` goes loading → loaded or loading → error), user action handling, and correct property updates.

### Snapshot Tests (swift-snapshot-testing by PointFree)
- Visual regression testing for UI components and screens
- **Components:** song row, player controls, loading/error states
- **Screens:** home screen, player screen — in populated, empty, and error configurations
- **Variants:** iPhone SE + iPhone 16, light + dark mode
- Reference images stored in `__Snapshots__/` directories alongside test files
- Use `assertSnapshot(of:as:)` with `.image` strategy

### Mocking Strategy
- Every protocol gets a corresponding `Mock` (e.g., `MockNetworkService`, `MockSongsRepository`)
- Mocks stored in `Tests/Mocks/`
- Mocks record calls and allow configurable return values / errors

## State Handling

```swift
enum ViewState<T: Sendable>: Sendable {
    case idle
    case loading
    case loaded(T)
    case error(Error)
}
```

Use in ViewModels to drive UI. Views switch on this enum to render appropriate states.

## Features

### Home Screen
- List of songs fetched from API with pagination (infinite scroll)
- Recently played songs section (from Core Data)
- Pull-to-refresh via `.refreshable`
- Loading/error/empty states

### Player Screen
- Play/pause, forward/backward controls
- Song timeline display (current time / total duration)
- Seek slider (drag to position — optional)
- Album art and song metadata

## Code Style

- No force unwraps (`!`) — use `guard let` or `if let`
- `guard` for early returns
- Extensions in separate files when non-trivial
- Prefer value types (`struct`) for models; `class` only when reference semantics needed
- Accessibility: add `.accessibilityLabel` and `.accessibilityHint` to interactive elements
- No `print()` in production code — use `os.Logger` if logging is needed

## Build & Run

```bash
# Build
xcodebuild -scheme moisesai-iphone-challenge -destination 'platform=iOS Simulator,name=iPhone 16' build

# Test
xcodebuild -scheme moisesai-iphone-challenge -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Dependencies

- **swift-snapshot-testing** (PointFree) — snapshot/visual regression tests
- No other third-party dependencies — use Apple frameworks only
