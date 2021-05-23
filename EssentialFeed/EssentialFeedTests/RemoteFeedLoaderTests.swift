//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 09.05.21.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromClient() {
        let url: URL = .given
        let client = makeSpyClientAndRemoteLoader(from: url).client

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataURLFromClient() {
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func testOneLoadDoesNotLoadMoreThanOneTime() {
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()

        XCTAssertEqual(client.requestedURLs.count, 1)
    }

    func test_loadTwice_requestDataFromClientTwice() {
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()
        loader.load()

        XCTAssertEqual(client.requestedURLs.count, 2)
        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func testLoaderReturnsExpectedErrorWhenClientFails() {
        // Arrange
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)
        client.error = NSError.testing

        // Act
        var capturedErrors: [RemoteFeedLoader.Error] = []
        loader.load { capturedErrors.append($0) }

        // Assert
        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    private func makeSpyClientAndRemoteLoader(from url: URL) -> (client: HTTPSpyClient, loader: RemoteFeedLoader) {
        let spyClient = HTTPSpyClient()
        let loader = RemoteFeedLoader(url: url, client: spyClient)
        return(spyClient, loader)
    }
}


final class HTTPSpyClient: HTTPClient {

    var requestedURLs: [URL?] = []
    var error: Error?

    func request(from url: URL, completion: (Error) -> Void) {
        if let error = error {
            completion(error)
        }
        requestedURLs.append(url)
    }
}

private extension URL {
    static let given = URL(string: "https://a-given-url.com")!
}

private extension NSError {
    static let testing = NSError(domain: "test", code: 0)
}
