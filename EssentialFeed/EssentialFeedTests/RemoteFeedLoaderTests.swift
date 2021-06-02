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

        expect(loader, toCompleteWithResult: .failure(.connectivity)) {
            client.complete(with: NSError.testing)
        }
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

            expect(loader, toCompleteWithResult: .failure(.invalidData)) {
                let itemJSON = makeItemJSON([])
                client.complete(with: statusCode, data: itemJSON, at: index)
            }
        }
    }

    func test_load_deliversErrorOn200ResponseWithInvalidJSON() {
        let (client, sut) = makeSpyClientAndRemoteLoader(from: .given)
        [
            Data(count: 2),
            Data("Invalid JSON".utf8)
        ]
        .enumerated()
        .forEach { index, data in
            expect(sut, toCompleteWithResult: .failure(.invalidData)) {
                client.complete(with: 200, data: data, at: index)
            }
        }
    }

    func test_load_deliversNoItemOn200HTTPResponseWithEmptyJSONList() {
        let (client, sut) = makeSpyClientAndRemoteLoader(from: .given)
        expect(sut, toCompleteWithResult: .success([])) {
            let itemJSON = makeItemJSON([])
            client.complete(with: 200, data: itemJSON)
        }
    }

    func test_load_deliversItemsOn200HTTPResponseWithJsonItems() {
        let (client, sut) = makeSpyClientAndRemoteLoader(from: .given)

        let item1 = makeItemAndBuildJSON(
            id: UUID(),
            imageURL: .given)

        let item2 = makeItemAndBuildJSON(
            id: UUID(),
            imageURL: .given,
            description: "a description",
            location: "a location")

        let expectedItems = [item1.model, item2.model]

        expect(sut, toCompleteWithResult: .success(expectedItems)) {
            let itemJSON = makeItemJSON([item1.json, item2.json])
            client.complete(with: 200, data: itemJSON)
        }
    }

    // MARK: Helper methods
    private func makeSpyClientAndRemoteLoader(from url: URL) -> (client: HTTPSpyClient, loader: RemoteFeedLoader) {
        let spyClient = HTTPSpyClient()
        let loader = RemoteFeedLoader(url: url, client: spyClient)
        return(spyClient, loader)
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result: LoaderResult, on clientAction: () -> Void, file: StaticString = #filePath, line: UInt = #line ) {

        var capturedResults = [LoaderResult]()
        sut.load { capturedResults.append($0) }

        clientAction()

        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }

    private func makeItemAndBuildJSON(id: UUID, imageURL: URL, description: String? = nil, location: String? = nil) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(
            id: id,
            imageURL: imageURL,
            description: description,
            location: location)

        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { acc, element in
            if let value = element.value {
                acc[element.key] = value
            }
        }
        return (item, json)
    }

    private func makeItemJSON(_ items: [[String : Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}


/// A Spy client just to capture values 🙉 without behaviour.
/// A normal Client completes with Error, then the spy client
/// should record that.

final class HTTPSpyClient: HTTPClient {

    typealias Message = (url: URL, completion: (ClientResult) -> Void)

    var requestedURLs: [URL] {
        messages.map { $0.url }
    }

    var messages: [Message] = []

    func request(from url: URL, completion: @escaping (ClientResult) -> Void) {
        messages.append((url, completion))
    }

    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }

    func complete(with statusCode: Int, data: Data, at index: Int = 0) {

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
