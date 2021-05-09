//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 09.05.21.
//

import XCTest

class RemoteFeedLoader {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func load() {
        client.request(from: URL(string: "http://a-url.com")!)
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
        let spyClient = HTTPSpyClient()
        _ = RemoteFeedLoader(client: spyClient)

        XCTAssertNil(spyClient.requestedURL)
    }

    func testLoad_requestDataURL_fromClient() {
        let spyClient = HTTPSpyClient()
        let sut = RemoteFeedLoader(client: spyClient)

        sut.load()

        XCTAssertNotNil(spyClient.requestedURL)
    }
}
