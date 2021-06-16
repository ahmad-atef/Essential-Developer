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
    private let session: URLSession

    init(session: URLSession = .shared) {
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


    // Fail Test
    func test_getFromURL_failsWithExpectedErrorOnRequestError() {

        URLProtocol.registerClass(URLProtocolStub.self)
        let url = URL(string: "http://given-url.com")!
        let expectedError = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(url: url, stub: .init(error: expectedError))

        let sut = RemoteClient()

        let exp = expectation(description: "Wait for completion")
        sut.get(from: url, completion: { result in

            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError.code, expectedError.code)
            default:
                XCTFail("")
            }

            exp.fulfill()
        })


        wait(for: [exp], timeout: 1.0)
        URLProtocol.unregisterClass(URLProtocolStub.self)
    }
}

// MARK: - Test Helpers
// Spy for the session, that will be injected to the client (SUT)
// The main function here is the dataTask(with url), which returns a URLSessionDataTask instance
// So we need a fake URLSessionDataTask 😼 (aka: DataTask)

// We will use the recommended way from Apple to test network requests,
// which is using the URLProtocol approach, so we will be the network system
// that will handle the URL requests protocols.
// So we will start by subclassing URLProtocol class
//Required methods when subclassing:
//class func canInit(with:URLRequest) -> Bool
//class func canonicalRequest(for:URLRequest)
//func startLoading()
//func stopLoading()

private class URLProtocolStub: URLProtocol {

    struct Stub {
        let error: NSError?
        init(error: NSError? = nil) {
            self.error = error
        }
    }
    static var messages = [URL: Stub]() // like a logger 🪵 [ "http://a-given-url.com": stubObject ]

    static func stub(url: URL, stub: Stub) { // shortcut to mock wanted behaviour 😉
        messages[url] = stub
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return messages[url] != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else {
            return
        }
        if let error = URLProtocolStub.messages[url]?.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() { }
}
