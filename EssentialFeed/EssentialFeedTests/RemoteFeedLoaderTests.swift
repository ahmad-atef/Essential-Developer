//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 09.05.21.
//

import XCTest
import EssentialFeed

final class HTTPSpyClient: HTTPClient {
    var requestedURLs: [URL?] = []

    func request(from url: URL){
        requestedURLs.append(url)
    }
}

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromClient() {
        let url = URL(string: "https://a-given-url.com")!
        let client = makeSpyClientAndRemoteLoader(from: url).client

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataURLFromClient() {
        let url = URL(string: "https://a-given-url.com")!
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func testOneLoadDoesNotLoadMoreThanOneTime() {
        let url = URL(string: "https://a-given-url.com")!
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()

        XCTAssertEqual(client.requestedURLs.count, 1)
    }

    func test_loadTwice_requestDataFromClientTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()
        loader.load()

        XCTAssertEqual(client.requestedURLs.count, 2)
        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    private func makeSpyClientAndRemoteLoader(from url: URL) -> (client: HTTPSpyClient, loader: RemoteFeedLoader) {
        let spyClient = HTTPSpyClient()
        let loader = RemoteFeedLoader(url: url, client: spyClient)
        return(spyClient, loader)
    }
}
