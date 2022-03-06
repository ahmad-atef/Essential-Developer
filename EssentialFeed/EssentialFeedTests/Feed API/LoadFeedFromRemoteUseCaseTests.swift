//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 09.05.21.
//

import XCTest
import EssentialFeed

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {

    func test_init_doesNotRequestDataFromClient() {
        let url: URL = .given
        let client = makeSpyClientAndRemoteLoader(from: url).client

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataURLFromClient() {
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.loadFeed(completion: { _ in })

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_load_doesNotRequestMoreThanOnce() {
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.loadFeed(completion: { _ in })

        XCTAssertEqual(client.requestedURLs.count, 1)
    }

    func test_loadTwice_requestDataFromClientTwice() {
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.loadFeed(completion: { _ in } )
        loader.loadFeed(completion: { _ in } )

        XCTAssertEqual(client.requestedURLs.count, 2)
        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func testLoaderReturnsExpectedErrorWhenClientFails() {
        // Arrange
        // Given
        let url: URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        expect(loader, toCompleteWithResult: .failure(RemoteFeedLoader.Error.connectivity)) {
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

            expect(loader, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData)) {
                let itemJSON = makeItemJSON([]) // doesn't matter, it should fail any way, because the response comes with status code anything but 200, which is the only one we reply with success 😼
                client.complete(with: statusCode, data: itemJSON, at: index)
            }
        }
    }

    func test_load_deliversErrorOn200ResponseWithInvalidJSON() {
        let (client, sut) = makeSpyClientAndRemoteLoader(from: .given)
        
        let corruptedData = [
            Data(count: 2),
            Data("Invalid JSON".utf8)
        ]

        corruptedData
            .enumerated()
            .forEach { index, data in
                expect(sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData)) {
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

    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let client = HTTPSpyClient()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: .given, client: client)

        var capturedResult = [FeedLoaderResult]()

        sut?.loadFeed(completion: { result in
            capturedResult.append(result)
        })

        sut = nil
        client.complete(with: 200, data: makeItemJSON([]))

        XCTAssertTrue(capturedResult.isEmpty)
    }

    // MARK: Helper methods
    // We need to make sure that the load and the client is deallocated after the test has finished,
    // we want to simulate the real life production scenario, where we expect that the client and loader
    // should be removed from memory after usage.
    private func makeSpyClientAndRemoteLoader(from url: URL, file: StaticString = #filePath, line: UInt = #line) -> (client: HTTPSpyClient, loader: RemoteFeedLoader) {
        let spyClient = HTTPSpyClient()
        let loader = RemoteFeedLoader(url: url, client: spyClient)
        
        trackForMemoryLeaks(spyClient)
        trackForMemoryLeaks(loader)

        return(spyClient, loader)
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult: FeedLoaderResult, on clientAction: () -> Void, file: StaticString = #filePath, line: UInt = #line ) {

        let expectation = expectation(description: "Wait for load completion")

        sut.loadFeed { receivedResult in

            switch (receivedResult, expectedResult) {

            case (.success(let receivedFeedItem), .success(let expectedFeedItem)):
                XCTAssertEqual(receivedFeedItem, expectedFeedItem, file: file, line: line)

            case (.failure(let receivedError as RemoteFeedLoader.Error), .failure(let expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected Result: \(expectedResult), Got Result: \(receivedResult)")
            }

            expectation.fulfill()
        }
        clientAction()

        wait(for: [expectation], timeout: 1.0)

    }

    private func makeItemAndBuildJSON(id: UUID, imageURL: URL, description: String? = nil, location: String? = nil) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL)

        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }

//        let reducedValues = [
//            "id": id.uuidString,
//            "description": description,
//            "location": location,
//            "image": imageURL.absoluteString
//        ].reduce(into: [String: Any]()) { acc, element in
//            if let value = element.value {
//                acc[element.key] = value
//            }
//        }
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

    // logger for the spy, just logging the messages as a key URL and a value completion client result.
    // as a result for that request.
    typealias Message = (url: URL, completion: (ClientResult) -> Void)

    // logger, everything (any request with its result) will be recorded here
    var messages: [Message] = []


    var requestedURLs: [URL] {
        messages.map { $0.url }
    }


    func get(from url: URL, completion: @escaping (ClientResult) -> Void) {
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
