import Testing
import Foundation
@testable import moisesai_iphone_challenge

@Suite("URLSessionNetworkService Tests")
struct URLSessionNetworkServiceTests {

    private func makeSUT() -> URLSessionNetworkService {
        MockURLProtocol.requestHandler = nil
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        return URLSessionNetworkService(session: session)
    }

    @Test func test_request_successfulResponse_decodesCorrectly() async throws {
        let sut = makeSUT()
        let jsonData = iTunesSearchResponseFixture.makeJSON()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonData)
        }

        let endpoint = Endpoint.searchSongs(term: "test", limit: 20, offset: 0)
        let result: iTunesSearchResponse = try await sut.request(endpoint)

        #expect(result.resultCount == 1)
        #expect(result.results.first?.trackName == "Get Lucky")
    }

    @Test func test_request_serverError_throwsRequestFailed() async throws {
        let sut = makeSUT()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let endpoint = Endpoint.searchSongs(term: "test", limit: 20, offset: 0)

        await #expect(throws: NetworkError.self) {
            let _: iTunesSearchResponse = try await sut.request(endpoint)
        }
    }

    @Test func test_request_invalidJSON_throwsDecodingFailed() async throws {
        let sut = makeSUT()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("not json".utf8))
        }

        let endpoint = Endpoint.searchSongs(term: "test", limit: 20, offset: 0)

        await #expect(throws: NetworkError.self) {
            let _: iTunesSearchResponse = try await sut.request(endpoint)
        }
    }

    @Test func test_request_badURL_throwsBadURL() async throws {
        let sut = makeSUT()
        let endpoint = Endpoint(baseURL: "not a url ://", path: "/test")

        await #expect(throws: NetworkError.self) {
            let _: iTunesSearchResponse = try await sut.request(endpoint)
        }
    }
}
