//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 09.05.21.
//

import XCTest

class RemoteFeedLoader {

    private let client: HTTPClient
    let url: URL

    init(url: URL = URL(string: "https://a-url.com")!, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    func load() {
        client.request(from: url)
    }
}

protocol HTTPClient {
    func request(from url: URL)
}

class HTTPSpyClient: HTTPClient {
    var requestedURL: URL?

    func request(from url: URL){
        self.requestedURL = url
    }
}

class RemoteFeedLoaderTests: XCTestCase {

    func testInitRemoteFeedLoader_doesNotRequestData_fromClient() {
        let url = URL(string: "https://a-given-url.com")!
        let client = makeSpyClientAndRemoteLoader(from: url).client

        XCTAssertNil(client.requestedURL)
    }

    func testLoad_requestDataURL_fromClient() {
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
