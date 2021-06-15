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

//Test behaviour, not framework (production) details
// So you free the production from any testing constrains 🆓
// Implement and maintain Only what you care about 👌

class RemoteClient {
    private let session: HTTPSession

    init(session: HTTPSession) {
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

/// Protocol Based Mocking
// its pretty common to copy the methods from the framework, and create a protocol out of it 😼
protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPDataTask
}

protocol HTTPDataTask {
    func resume()
}

final class URLSessionHTTPClientTests: XCTestCase {

    // Create Test
    // test_sessionRequestsCorrectURLPassedFromClient
    func test_getFromURL_createsDataTaskWithURL() {
        let session = SpySession()
        let sut = RemoteClient(session: session)
        let url = URL(string: "http://any-url.com")!
        let task = FakeURLSessionDataTask()
        session.stub(url: url, stub: SpySession.Stub(task: task))
        sut.get(from: url, completion: { _ in })

        XCTAssertEqual(session.requestURLs, [url])
    }

    // Resume Test
    // same approach, but we can spy on the data task now 😺
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let session = SpySession()
        let task = SpySessionDataTask() // We need another wat... Spy 😼
        session.stub(url: url, stub: .init(task: task))

        let sut = RemoteClient(session: session)

        sut.get(from: url, completion: { _ in })

        XCTAssertEqual(task.resumedCallCount, 1) // production details, specific framework details, we shouldn't be testing that 🥲
    }

    // Fail Test
    func test_getFromURL_failsWithExpectedErrorOnRequestError() {

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
private class SpySession: HTTPSession {
    var requestURLs = [URL]()
    var dataTask: HTTPDataTask?

    struct Stub {
        let task: HTTPDataTask
        let error: NSError?

        init(task: HTTPDataTask, error: NSError? = nil) {
            self.task = task
            self.error = error
        }
    }

    var messages = [URL: Stub]() // like a logger 🪵

    func stub(url: URL, stub: Stub) { // shortcut to mock wanted behaviour 😉
        messages[url] = stub
    }

    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPDataTask {
        requestURLs.append(url)
        guard let stub = messages[url] else {
            fatalError("Couldn't find Stub")
        }
        completionHandler(nil, nil, stub.error)
        return stub.task
    }
}

private class FakeURLSessionDataTask: HTTPDataTask {
    func resume() {}
}

private class SpySessionDataTask: HTTPDataTask {
    var resumedCallCount: Int = 0

    func resume() {
        resumedCallCount += 1
    }
}
