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

        loader.load(completion: { _ in })

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_load_doesNotRequestMoreThanOnce() {
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load(completion: { _ in })

        XCTAssertEqual(client.requestedURLs.count, 1)
    }

    func test_loadTwice_requestDataFromClientTwice() {
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load(completion: { _ in } )
        loader.load(completion: { _ in } )

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

    func testReturnsInvalidDataError_When_ClientReturnsNon200Response() {

        // Arrange
        // Given
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        // Act
        // When
        [
            199,
            201,
            400
        ]
        .enumerated()
        .forEach { index, statusCode  in
            var capturedErrors: RemoteFeedLoader.Error?
            loader.load { capturedErrors = $0 }

            client.complete(with: statusCode, at: index)

            // Assert
            // Then
            XCTAssertEqual(capturedErrors, .invalidData)
        }

    }

    func test_load_deliversErrorOn200ResponseWithInvalidJSON() {
        let (client, sut) = makeSpyClientAndRemoteLoader(from: .given)

        let data = Data(count: 2)
        let invalidJson = Data("Invalid JSON".utf8)

        [data, invalidJson]
            .enumerated()
            .forEach { index, data in

            var error: RemoteFeedLoader.Error?

            sut.load { error = $0 }
            client.complete(with: 200, data: data, at: index)

            XCTAssertEqual(error, .invalidData)
        }

    }
    private func makeSpyClientAndRemoteLoader(from url: URL) -> (client: HTTPSpyClient, loader: RemoteFeedLoader) {
        let spyClient = HTTPSpyClient()
        let loader = RemoteFeedLoader(url: url, client: spyClient)
        return(spyClient, loader)
    }
}


/// A Spy client just to capture values 🙉 without behaviour.
/// A normal Client completes with Error, then the spy client
/// should record that.

final class HTTPSpyClient: HTTPClient {

    typealias Completion = (Result<(Any, Any),Error>) -> ()
    typealias Message = (url: URL, completion: Completion)

    var requestedURLs: [URL] {
        messages.map { $0.url }
    }

    var messages: [Message] = []

    func request(from url: URL, completion: @escaping Completion) {
        messages.append((url, completion))
    }

    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }

    func complete(with statusCode: Int, data: Data = Data(), at index: Int = 0) {

        let response = HTTPURLResponse(
            url: requestedURLs[index],
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil)!
        messages[index].completion(.success((data, response)))
    }
}

private extension URL {
    static let given = URL(string: "https://a-given-url.com")!
}

private extension NSError {
    static let testing = NSError(domain: "test", code: 0)
}
