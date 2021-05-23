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
        // Given
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)


        // Act
        // When
        var capturedErrors = [RemoteFeedLoader.Error]()
        loader.load { capturedErrors.append($0) }
        let clientError = NSError.testing
        client.complete(with: clientError)

        // Assert
        // Then
        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    private func makeSpyClientAndRemoteLoader(from url: URL) -> (client: HTTPSpyClient, loader: RemoteFeedLoader) {
        let spyClient = HTTPSpyClient()
        let loader = RemoteFeedLoader(url: url, client: spyClient)
        return(spyClient, loader)
    }
}


/// A Spy client just to capture values 🙉 without behaviour.

final class HTTPSpyClient: HTTPClient {

    typealias Completion = (Error) -> ()
    typealias Message = (url: URL, completion: Completion)

    var requestedURLs: [URL?] {
        messages.map { $0.url }
    }

    var messages: [Message] = []

    func request(from url: URL, completion: @escaping Completion) {
        messages.append((url, completion))
    }

    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(error)
    }
}

private extension URL {
    static let given = URL(string: "https://a-given-url.com")!
}

private extension NSError {
    static let testing = NSError(domain: "test", code: 0)
}
