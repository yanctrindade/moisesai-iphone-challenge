# Plan: Moises AI iPhone Challenge — Full App Implementation

## Context
Build a music player app that searches songs via the Apple iTunes Search API, caches results with Core Data, and plays audio previews. The app has 4 screens + 1 bottom sheet: Splash, Home (Songs), Player, Album, and a More Options bottom sheet. We'll implement screen by screen after the user provides design screenshots.

## iTunes Search API
- **Base URL:** `https://itunes.apple.com/search`
- **Key params:** `term` (search query), `media=music`, `entity=song`, `limit` (1-200, default 50), `offset` (for pagination), `country`
- **Response:** `{ resultCount: Int, results: [Track] }`
- **Rate limit:** ~20 calls/minute
- **Track fields:** trackId, trackName, artistName, collectionName, artworkUrl100, previewUrl (30s AAC), trackTimeMillis, primaryGenreName, releaseDate, collectionId, etc.
- **No auth required**

---

## High-Level Architecture

```
App Entry (Splash) → NavigationStack
  ├── Home (Songs Screen) — search + recently played
  │   ├── → Player (Song Details) — push
  │   ├── → Album Screen — push
  │   └── → More Options — bottom sheet
  └── Router manages NavigationPath
```

---

## Branching & PRs
Each screen/phase gets its own feature branch and PR:
- Phase 1 (Core Infrastructure): `feature/core-infrastructure` → PR to `main`
- Phase 2 (Splash): `feature/splash-screen` → PR to `main`
- Phase 3 (Home): `feature/home-screen` → PR to `main`
- Phase 4 (Player): `feature/player-screen` → PR to `main`
- Phase 5 (More Options): `feature/more-options-sheet` → PR to `main`
- Phase 6 (Album): `feature/album-screen` → PR to `main`
- Phase 7 (Testing): `feature/tests` → PR to `main`

## Implementation Order

### Phase 1: Core Infrastructure
Build the foundation before any screens.

**1.1 — Network Layer**
- `Endpoint` enum/struct (baseURL, path, queryItems, method)
- `NetworkServiceProtocol` + `URLSessionNetworkService`
- `NetworkError` enum
- iTunes-specific endpoint: `.searchSongs(term:limit:offset:)`

**1.2 — Data Layer (Core Data) — Offline-First**
- `MoisesAI.xcdatamodeld` with entities: `CachedSong`, `RecentlyPlayedSong`
- `PersistenceController` (shared + preview/test in-memory)
- `NSManagedObject` subclasses
- Repository protocols + implementations
- **Offline-first strategy everywhere:**
  1. Show cached data immediately (no loading spinner if cache exists)
  2. Fetch fresh data from API in background
  3. Update UI silently when fresh data arrives
  4. Loading state only shown when cache is empty (e.g., first-ever launch)

**1.3 — Domain Models**
- `Song` struct (domain model, `Sendable`)
- `iTunesSearchResponse` / `iTunesTrack` (DTO, `Decodable`)
- Mappers: DTO → Domain, CoreData Entity ↔ Domain

**1.4 — Navigation**
- `Route` enum (home, player(Song), album(albumId, albumName))
- `Router` class (`@Observable`, owns `NavigationPath`)
- Root `ContentView` with `NavigationStack(path:)`

**1.5 — Shared UI**
- Common components (async image loader, error view, loading view)
- No global `ViewState<T>` — each ViewModel defines its own `ViewState` and `Action` enums (see pattern below)

---

### Design System
Use iOS system/semantic colors + a few custom named colors.
- **Splash background:** `Base/Gradient/Spotlight` — `linear-gradient(39.45deg, #000000 33.57%, #0086A0 205.11%)` (mostly black with subtle teal in far corner)
- **All other screens background:** `#000000` (pure black)
- **Text primary:** `.primary` (white in dark mode)
- **Text secondary:** `.secondary` (gray in dark mode)
- **Accent/Tint:** `.tint` / `.accentColor` (system default)
- **Surfaces/Cards:** `Color(.secondarySystemBackground)`
- **Separators:** `Color(.separator)`
- **Icons:** SF Symbols, `.secondary` or `.primary` foreground
- **Typography:** System font (SF Pro) as default, with architecture ready to swap in custom font (Articulat CF) later
  - Player song title: weight 600, 32px, line-height 120%
  - Player artist name: weight 500 (Medium), 16px, line-height 120%
  - Other screens: system `.headline`, `.subheadline`, `.caption` etc.
- **App appearance:** Force dark mode (`.preferredColorScheme(.dark)`)
- **Named colors in asset catalog:**
  - `Base/Gradient/Spotlight` — splash gradient

### Phase 2: Splash Screen
- Background: `Base/Gradient/Spotlight` gradient (39.45deg, #000000 at 33.57% → #0086A0 at 205.11%)
- Centered music note icon (app icon asset, 100x100pt)
- Static hold ~2 seconds, then fade transition to Home
- No data preloading — purely visual

---

### Phase 3: Home Screen (Songs)
The main screen — search songs and view recently played.

**ViewModel:** `HomeViewModel`
- Search text binding with debounce (~500ms)
- `ViewState` for search results
- Recently played songs list (from Core Data)
- Pagination: load more on scroll to bottom (offset += limit)
- Pull-to-refresh

**UseCase:** `SearchSongsUseCase`, `GetRecentlyPlayedUseCase`

**Repository:** `SongsRepository` (protocol)
- `searchSongs(term:limit:offset:)` → fetches from network, caches to Core Data
- `getRecentlyPlayed()` → reads from Core Data

**View:** `HomeView`
- Top bar: search icon (SF `magnifyingglass`, top-left circular button) + "Songs" title (center)
- Song rows: square album art (~50pt, rounded corners) | title (16px, medium 500, `.primary`) + artist (12px, medium 500, `.secondary`) | `...` button (SF `ellipsis`)
- No row separators — clean spacious layout
- Background: pure black `#000000`
- First launch (no cache): empty list with search prompt
- Subsequent launches: immediately show cached last search results
- Infinite scroll pagination
- `.refreshable` for pull-to-refresh
- Tap song row → push to Player
- Tap `...` → More Options bottom sheet
- Search: show cached results for same query instantly, refresh from API in background

---

### Phase 4: Player Screen (Song Details)
Full-screen audio player.

**ViewModel:** `PlayerViewModel`
- Owns `AVPlayer` for 30s preview playback
- Play/pause state, current time, total duration
- Forward/backward (skip to next/previous song in list)
- Seek slider (optional drag-to-seek)
- Marks song as recently played in Core Data

**UseCase:** `PlaySongUseCase`, `SaveRecentlyPlayedUseCase`

**View:** `PlayerView`
- **Nav bar:** back chevron (left) + album title (center, `.secondary`) + `...` (right, More Options)
- **Album artwork:** 264x264pt, centered, rounded corners
- **Song title:** 32px, semibold (600), white, centered, line-height 120%
- **Artist name:** 16px, medium (500), `.secondary`, line-height 120%
- **Repeat icon:** right-aligned next to artist — toggles repeat mode (off / one / all)
- **Timeline:** thin slider, current time left ("1:26"), remaining time right ("-2:54"), `.caption`, `.secondary`
- **Seek slider:** drag-to-seek (optional)
- **Transport controls:** rewind (`backward.fill`) | play/pause (large circle, ~64pt) | forward (`forward.fill`)
- **Background:** pure black `#000000`
- Tapping album title in nav bar → Album screen
- `...` → More Options bottom sheet

---

### Phase 5: More Options Bottom Sheet
Presented as `.sheet` with `.presentationDetents([.medium])`.

- Triggered from `...` button on song rows (Home) and Player nav bar
- No design screenshot — we'll follow iOS system patterns
- **Options:**
  - View Album → push to Album screen
  - Share → system share sheet (song name + preview URL)
  - Add to Favorites / Remove from Favorites (toggle, persisted in Core Data)
- Song info header at top (artwork thumbnail + title + artist)
- List-style options with SF Symbol icons
- Background: `.secondarySystemBackground`

---

### Phase 6: Album Screen
Shows all songs from a specific album.

**ViewModel:** `AlbumViewModel`
- Fetches songs by `collectionId` using iTunes lookup API (`https://itunes.apple.com/lookup?id={collectionId}&entity=song`)
- `ViewState` for album tracks

**UseCase:** `FetchAlbumSongsUseCase`

**View:** `AlbumView`
- **Nav bar:** back chevron (left), no title
- **Album header (centered):**
  - Album artwork (~120pt, rounded corners, centered)
  - Album title — bold, white (specs TBD from Figma for header size)
  - Artist name — `.secondary`
- **Track rows:**
  - Small album art thumbnail (~44pt, rounded corners) left
  - Title: 16px, medium (500), `.primary`, line-height 120%
  - Subtitle (artist): 12px, medium (500), `.secondary`, line-height 140%
  - No `...` button, no separators
- **Background:** pure black `#000000`
- Tap track → push to Player

---

### Phase 7: Testing
After all screens are built.

**Unit Tests:**
- `URLSessionNetworkService` — mock URLProtocol
- `SongsRepository` — mock service + in-memory Core Data
- `SearchSongsUseCase`, `FetchAlbumSongsUseCase` — mock repository
- `HomeViewModel`, `PlayerViewModel`, `AlbumViewModel` — mock use cases

**Snapshot Tests:**
- Song row component, player controls, loading/error states
- Home screen, player screen, album screen (populated, empty, error)
- iPhone SE + iPhone 16, light + dark mode

---

## Project Structure (inside main app target: moisesai-iphone-challenge/)
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
│   │   └── NetworkError.swift
│   ├── Data/
│   │   ├── PersistenceController.swift
│   │   ├── MoisesAI.xcdatamodeld
│   │   └── Entities/ (NSManagedObject subclasses)
│   ├── Domain/
│   │   ├── Models/Song.swift
│   │   └── DTOs/iTunesSearchResponse.swift
│   ├── Navigation/
│   │   ├── Router.swift
│   │   └── Route.swift
│   └── UI/
│       (no shared ViewState — each ViewModel defines its own)
│       └── Components/ (shared views)
├── Modules/
│   ├── Splash/
│   │   └── SplashView.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   ├── SearchSongsUseCase.swift
│   │   ├── GetRecentlyPlayedUseCase.swift
│   │   ├── SongsRepositoryProtocol.swift
│   │   ├── SongsRepository.swift
│   │   └── Components/
│   ├── Player/
│   │   ├── PlayerView.swift
│   │   ├── PlayerViewModel.swift
│   │   ├── AudioPlayerService.swift
│   │   └── Components/
│   ├── Album/
│   │   ├── AlbumView.swift
│   │   ├── AlbumViewModel.swift
│   │   ├── FetchAlbumSongsUseCase.swift
│   │   └── Components/
│   └── MoreOptions/
│       └── MoreOptionsSheet.swift
└── Tests/
    ├── Mocks/
    ├── Unit/
    │   ├── Network/
    │   ├── Repositories/
    │   ├── UseCases/
    │   └── ViewModels/
    └── Snapshot/
        ├── Components/
        └── Screens/
```

## ViewModel Pattern: Action + ViewState

Each ViewModel defines its own `Action` enum (user intents) and `ViewState` enum (screen state). The ViewModel exposes a `send(_ action:)` method. Views call `send()` for all interactions.

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
    private(set) var recentlyPlayed: [Song] = []

    func send(_ action: Action) {
        switch action {
        case .search(let term):
            Task { await performSearch(term) }
        // ...
        }
    }
}

// View calls:
viewModel.send(.search("jack johnson"))
viewModel.send(.refresh)
```

## Schemes & Build Configurations

Two schemes with full environment separation:

| | **Staging** | **App Store** |
|---|---|---|
| **Scheme** | `moisesai-iphone-challenge-staging` | `moisesai-iphone-challenge` |
| **Build Config** | Debug-Staging / Release-Staging | Debug / Release |
| **Bundle ID** | `br.com.yantrindade.moisesai-iphone-challenge.staging` | `br.com.yantrindade.moisesai-iphone-challenge` |
| **Display Name** | `Moises (Staging)` | `Moises` |
| **App Icon** | Staging icon (badge overlay) | Production icon |
| **Base URL** | Same API (iTunes) but routed through config | Same API |
| **Logging** | Verbose (`os.Logger` at `.debug` level) | Minimal (`.error` only) |

**Implementation:**
- `.xcconfig` files per environment: `Staging.xcconfig`, `Production.xcconfig`
- `Environment.swift` — reads from Info.plist or build settings to expose current config
- Preprocessor flag or Info.plist key: `APP_ENVIRONMENT = staging | production`
- App icon asset catalogs: `AppIcon` (prod) + `AppIcon-Staging` (staging with badge)

## Pre-step: Save Plan
- Copy this plan to `docs/plans/plan-v1.md` for version tracking

## Pre-step: Move Xcode Project to Root
Currently the project is nested: `moisesai-iphone-challenge/moisesai-iphone-challenge/...`. Move the `.xcodeproj` and source folders up to the repo root so the structure is:
```
/ (repo root)
├── moisesai-iphone-challenge.xcodeproj/
├── moisesai-iphone-challenge/          (main app target sources)
├── moisesai-iphone-challengeTests/
├── moisesai-iphone-challengeUITests/
├── CLAUDE.md
├── .gitignore
└── README.md
```

## Key Files to Modify
- [ContentView.swift](moisesai-iphone-challenge/ContentView.swift) — replace with NavigationStack + Router
- [moisesai_iphone_challengeApp.swift](moisesai-iphone-challenge/moisesai_iphone_challengeApp.swift) — inject dependencies

## Verification
1. Build: `xcodebuild -scheme moisesai-iphone-challenge -destination 'platform=iOS Simulator,name=iPhone 16' build`
2. Run on simulator — test each screen flow
3. Test: `xcodebuild -scheme moisesai-iphone-challenge -destination 'platform=iOS Simulator,name=iPhone 16' test`
4. Verify offline-first: search songs, kill network, relaunch — cached results should show
5. Verify recently played: play a song, go home — it appears in recently played section

## Pre-step: Add Design Assets to docs/
- Create `docs/specs/` — screenshots of each screen for reference during implementation
- Create `docs/appicon/` — app icon source files
- User will provide both; save them in the respective directories

## Pending
- **Screenshots & assets** — user will provide, stored in `docs/specs/`
- **More Options sheet** — exact options TBD from design
- **Splash screen** — design TBD
