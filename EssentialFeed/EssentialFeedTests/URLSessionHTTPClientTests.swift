//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 11.06.21.
//

import XCTest
import EssentialFeed

// So the production implementation for Client, would be a real request for the API.
// We need to be able to test it first because we don't have API yet 🤗
// What will happen at the end of the day is a URLSession -> DataTaskWith(url) request, that return a completion block.
// So the RemoteClient will have the Session that do that ☝️
// And will have an API method get(from url) that will be the window to shot for the request.

// So Client has a Session 😉

class RemoteClient {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in }
    }

}
final class URLSessionHTTPClientTests: XCTestCase {

    // test_sessionRequestsCorrectURLPassedFromClient
    func test_getFromURL_createsDataTaskWithURL() {
        let session = SpySession()
        let sut = RemoteClient(session: session)
        let url = URL(string: "http://any-url.com")!

        sut.get(from: url)

        XCTAssertEqual(session.requestURLs, [url])
    }
}

// MARK: - Test Helpers
// Spy for the session, that will be injected to the client (SUT)
// The main function here is the dataTask(with url), which returns a URLSessionDataTask instance
// So we need a fake URLSessionDataTask 😼
private class SpySession: URLSession {
    var requestURLs = [URL]()

    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        requestURLs.append(url)
        return FakeURLSessionDataTask()
    }
}

private class FakeURLSessionDataTask: URLSessionDataTask {}
