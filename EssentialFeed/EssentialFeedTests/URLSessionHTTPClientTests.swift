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

    func get(from url: URL, completion: @escaping (ClientResult) -> Void ) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }

}
final class URLSessionHTTPClientTests: XCTestCase {

    // test_sessionRequestsCorrectURLPassedFromClient
    func test_getFromURL_createsDataTaskWithURL() {
        let session = SpySession()
        let sut = RemoteClient(session: session)
        let url = URL(string: "http://any-url.com")!

        sut.get(from: url, completion: { _ in })

        XCTAssertEqual(session.requestURLs, [url])
    }

    // same approach, but we can spy on the data task now 😺
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let session = SpySession()
        let task = SpySessionDataTask() // We need another wat... Spy 😼
        session.stub(url: url, stub: .init(task: task))

        let sut = RemoteClient(session: session)

        sut.get(from: url, completion: { _ in })

        XCTAssertEqual(task.resumedCallCount, 1)
    }

    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "http://given-url.com")!
        let session = SpySession()
        let task = SpySessionDataTask()
        let expectedError = NSError(domain: "", code: 0, userInfo: nil)
        session.stub(url: url, stub: .init(task: task, error: expectedError))

        let sut = RemoteClient(session: session)

        let exp = expectation(description: "Wait for completion")
        sut.get(from: url, completion: { result in

            switch result {
            case let .failure(error as NSError):
                XCTAssertEqual(error, expectedError)
            default:
                XCTFail("")
            }

            exp.fulfill()
        })


        wait(for: [exp], timeout: 1.0)
    }
}

// MARK: - Test Helpers
// Spy for the session, that will be injected to the client (SUT)
// The main function here is the dataTask(with url), which returns a URLSessionDataTask instance
// So we need a fake URLSessionDataTask 😼 (aka: DataTask)
private class SpySession: URLSession {
    var requestURLs = [URL]()
    var dataTask: URLSessionDataTask?

    struct Stub {
        let task: URLSessionDataTask
        let error: NSError?

        init(task: URLSessionDataTask, error: NSError? = nil) {
            self.task = task
            self.error = error
        }
    }

    var messages = [URL: Stub]()

    func stub(url: URL, stub: Stub) {
        messages[url] = stub
    }

    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        requestURLs.append(url)
        guard let stub = messages[url] else {
            fatalError("Couldn't find Stub")
        }
        completionHandler(nil, nil, stub.error)
        return stub.task
    }
}

private class FakeURLSessionDataTask: URLSessionDataTask {
    override func resume() {}
}

private class SpySessionDataTask: URLSessionDataTask {
    var resumedCallCount: Int = 0

    override func resume() {
        resumedCallCount += 1
    }
}
