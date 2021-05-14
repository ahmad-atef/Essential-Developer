//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 09.05.21.
//

import XCTest
import EssentialFeed

class HTTPSpyClient: HTTPClient {
    var requestedURL: URL?

    func request(from url: URL){
        self.requestedURL = url
    }
}

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromClient() {
        let url = URL(string: "https://a-given-url.com")!
        let client = makeSpyClientAndRemoteLoader(from: url).client

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestsDataURLFromClient() {
        let url = URL(string: "https://a-given-url.com")!
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()

        XCTAssertEqual(client.requestedURL, url)
    }

    private func makeSpyClientAndRemoteLoader(from url: URL) -> (client: HTTPSpyClient, loader: RemoteFeedLoader) {
        let spyClient = HTTPSpyClient()
        let loader = RemoteFeedLoader(url: url, client: spyClient)
        return(spyClient, loader)
    }
}
