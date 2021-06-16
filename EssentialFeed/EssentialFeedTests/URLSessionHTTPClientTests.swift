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
        let url = URL(string: "http://a-wrong-url.com")!
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

        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://given-url.com")!
        let expectedError = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)

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
        URLProtocolStub.stopInterceptingRequest()
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
        let data: Data?
        let response: URLResponse?
        let error: NSError?

        init(data: Data?, response:URLResponse?, error: NSError? = nil) {
            self.data = data
            self.response = response
            self.error = error
        }
    }
    static var stub: Stub? // like a logger 🪵 [ "http://a-given-url.com": stubObject ]
    static func stub(data: Data?, response: URLResponse?, error: NSError?) { // shortcut to mock wanted behaviour 😉
        stub = Stub(data: data, response: response, error: error)
    }

    static func startInterceptingRequests(){
        URLProtocol.registerClass(self)
    }

    static func stopInterceptingRequest() {
        URLProtocol.unregisterClass(self)
        stub = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard request.url != nil else { return }
        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        else if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}
