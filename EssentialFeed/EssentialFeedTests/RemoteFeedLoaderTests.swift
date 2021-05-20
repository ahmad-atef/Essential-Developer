//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 09.05.21.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {

    func testLoaderDoesNotRequestDataFromClientOnInit() {
        let url:URL = .given
        let client = makeSpyClientAndRemoteLoader(from: url).client

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func testLoaderRequestsDataURLFromClientOnLoad() {

        let url:URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func testLoaderRequestsDataURLFromClientOnLoadOnlyOnce() {
        let url = URL(string: "https://a-given-url.com")!
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()

        XCTAssertEqual(client.requestedURLs.count, 1)
    }

    func testLoaderCanMakeMoreThanOneRequestFromClient() {
        let url:URL = .given
        let (client, loader) = makeSpyClientAndRemoteLoader(from:url)

        loader.load()
        loader.load()

        XCTAssertEqual(client.requestedURLs.count, 2)
        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func testLoaderReturnsExpectedErrorWhenClientFails() {

        let client = HTTPSpyClient()
        let loader = RemoteFeedLoader(url: .given, client: client)

        client.didFail = true

        loader.load { error in
            XCTAssertEqual(error, .connectivity)
        }
    }

    private func makeSpyClientAndRemoteLoader(from url: URL) -> (client: HTTPSpyClient, loader: RemoteFeedLoader) {
        let spyClient = HTTPSpyClient()
        let loader = RemoteFeedLoader(url: url, client: spyClient)
        return(spyClient, loader)
    }
}


private final class HTTPSpyClient: HTTPClient {
    var requestedURLs: [URL?] = []
    var didFail: Bool = false

    func request(from url: URL, completion: (Error) -> Void) {
        if didFail {
            completion(NSError.test)
        }

        requestedURLs.append(url)
    }
}


private extension URL {
    static let given = URL(string: "http://a-given-url.com")!
}

private extension NSError {
    static let test = NSError(domain: "test", code: 1)
}
