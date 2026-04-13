import Testing
import Foundation
@testable import moisesai_iphone_challenge

@Suite("Endpoint Tests")
struct EndpointTests {

    @Test func test_searchSongs_buildsCorrectURL() {
        let endpoint = Endpoint.searchSongs(term: "daft punk", limit: 20, offset: 0)

        let url = endpoint.url
        #expect(url != nil)

        let urlString = url!.absoluteString
        #expect(urlString.contains("itunes.apple.com/search"))
        #expect(urlString.contains("term=daft%20punk"))
        #expect(urlString.contains("media=music"))
        #expect(urlString.contains("entity=song"))
        #expect(urlString.contains("limit=20"))
        #expect(urlString.contains("offset=0"))
    }

    @Test func test_searchSongs_withOffset_includesOffset() {
        let endpoint = Endpoint.searchSongs(term: "test", limit: 10, offset: 40)

        let urlString = endpoint.url!.absoluteString
        #expect(urlString.contains("offset=40"))
        #expect(urlString.contains("limit=10"))
    }

    @Test func test_searchSongs_usesGetMethod() {
        let endpoint = Endpoint.searchSongs(term: "test", limit: 20, offset: 0)
        #expect(endpoint.method == .get)
    }

    @Test func test_lookupAlbum_buildsCorrectURL() {
        let endpoint = Endpoint.lookupAlbum(collectionId: 12345)

        let url = endpoint.url
        #expect(url != nil)

        let urlString = url!.absoluteString
        #expect(urlString.contains("itunes.apple.com/lookup"))
        #expect(urlString.contains("id=12345"))
        #expect(urlString.contains("entity=song"))
    }

    @Test func test_endpoint_withInvalidBaseURL_returnsNilURL() {
        let endpoint = Endpoint(baseURL: "not a url ://", path: "/test")
        #expect(endpoint.url == nil)
    }
}
