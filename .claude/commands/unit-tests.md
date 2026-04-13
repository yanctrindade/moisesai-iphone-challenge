# Unit Test Generator

Generate unit tests for this iOS project following the established patterns.

## Input

Accepts either:
- A **specific file path**: e.g., `HomeViewModel.swift` — generates tests for that file
- A **layer name**: `viewmodels`, `services`, `repositories`, `usecases` — generates tests for all files in that layer

Argument: $ARGUMENTS

## Instructions

1. **Identify targets**: Based on the argument, find the source file(s) to test.
   - If a file path: locate it under `moisesai-iphone-challenge/`
   - If a layer name:
     - `viewmodels` → all `*ViewModel.swift` files in `Modules/`
     - `usecases` → all `*UseCase.swift` files in `Modules/`
     - `repositories` → all `*Repository.swift` files (not protocols) in `Modules/`
     - `services` → all files in `Core/Network/` (excluding protocols)

2. **Read each target file** and its protocol/dependencies to understand:
   - Public methods to test
   - Dependencies (protocols) that need mocking
   - State types (ViewState, Action enums for ViewModels)

3. **Generate Mocks** in `moisesai-iphone-challengeTests/Mocks/`:
   - One mock per protocol dependency (e.g., `MockSongsRepository` for `SongsRepositoryProtocol`)
   - Mocks should:
     - Conform to the protocol
     - Store call counts and arguments for verification
     - Allow configurable return values and errors via properties
   - Skip if mock already exists

4. **Generate Test Files** in `moisesai-iphone-challengeTests/Unit/{Layer}/`:
   - Layer subfolder: `ViewModels/`, `UseCases/`, `Repositories/`, `Network/`
   - File naming: `{ClassName}Tests.swift`

5. **Test Framework**: Apple Testing (`import Testing`)
   - Use `@Suite` for the test struct
   - Use `@Test` for each test function
   - Use `#expect` and `#require` for assertions
   - All tests are `async throws`
   - Naming: `test_methodName_condition_expectedResult`

6. **Test patterns by layer**:

   **ViewModels**: Test Action → ViewState transitions
   - Send an action, verify state changed correctly
   - Test loading → loaded, loading → error flows
   - Test debounce/pagination behavior
   - Use mock use cases

   **UseCases**: Test business logic
   - Call execute, verify repository was called with correct params
   - Test data transformations
   - Test error propagation
   - Use mock repository

   **Repositories**: Test offline-first logic
   - Mock the network service
   - Use in-memory Core Data (`PersistenceController(inMemory: true)`)
   - Test: cache-first reads, network refresh, cache writes, fallback on error

   **Services (Network)**: Test request building and response parsing
   - Use mock `URLProtocol` subclass
   - Test: correct URL construction, header handling, response decoding, error mapping

7. **Build and verify**: After generating, run `xcodebuild -scheme moisesai-iphone-challenge -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` to verify tests compile and pass.

## Example Test Structure

```swift
import Testing
@testable import moisesai_iphone_challenge

@Suite("HomeViewModel Tests")
struct HomeViewModelTests {
    let mockSearchUseCase = MockSearchSongsUseCase()
    let mockRecentlyPlayedUseCase = MockGetRecentlyPlayedUseCase()

    private func makeSUT() -> HomeViewModel {
        HomeViewModel(
            searchSongsUseCase: mockSearchUseCase,
            getRecentlyPlayedUseCase: mockRecentlyPlayedUseCase
        )
    }

    @Test func test_send_searchWithTerm_setsLoadingThenLoaded() async throws {
        let sut = makeSUT()
        mockSearchUseCase.result = [Song.stub()]

        sut.send(.search("test"))
        // allow async work
        try await Task.sleep(for: .milliseconds(600))

        #expect(sut.state == .loaded([Song.stub()]))
    }

    @Test func test_send_searchWithTerm_whenError_setsErrorState() async throws {
        let sut = makeSUT()
        mockSearchUseCase.error = NetworkError.noConnection

        sut.send(.search("test"))
        try await Task.sleep(for: .milliseconds(600))

        if case .error(let message) = sut.state {
            #expect(message.contains("connection"))
        } else {
            Issue.record("Expected error state")
        }
    }
}
```
