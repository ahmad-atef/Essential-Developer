//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 11.06.21.
//

import XCTest
import EssentialFeed


final class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
        super.tearDown()
    }

    // Check for correct url & correct request type (GET)
    func test_getFromURL_performsCorrectGETRequest() {
        let url = URL.anyURL()
        let exp = expectation(description: "Wait for request")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in  }

        wait(for: [exp], timeout: 1.0)
    }

    // Should Fail when session returns Error
    func test_getFromURL_failsWithExpectedErrorOnRequestError() {
        let passedError = NSError.any

        let result = completeSession(data: nil, response: nil, error: passedError)

        if case .failure(let error as NSError) = result {
            XCTAssertEqual(error.code, passedError.code)
            XCTAssertEqual(error.domain, passedError.domain)
        } else {
            XCTFail()
        }
    }

    // test invalid scenarios
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(completeSession(data: nil, response: nil, error: nil))
        XCTAssertNotNil(completeSession(data: nil, response: URLResponse(), error: nil))
        XCTAssertNotNil(completeSession(data: nil, response: HTTPURLResponse(), error: nil))
        XCTAssertNotNil(completeSession(data: Data(), response: nil, error: nil))
        XCTAssertNotNil(completeSession(data: Data(), response: nil, error: NSError.any))
        XCTAssertNotNil(completeSession(data: nil, response: URLResponse(), error: NSError.any))
        XCTAssertNotNil(completeSession(data: nil, response: HTTPURLResponse(), error: NSError.any))
        XCTAssertNotNil(completeSession(data: Data(), response: URLResponse(), error: NSError.any))
        XCTAssertNotNil(completeSession(data: Data(), response: HTTPURLResponse(), error: NSError.any))
        XCTAssertNotNil(completeSession(data: nil, response: nil, error: NSError.any))
    }

    func test_getFromURL_SuccesssOnValidCases() {
        let result = completeSession(data: Data(), response: HTTPURLResponse(), error: nil)
        if case .success(let response) = result {
            XCTAssertNotNil(response.0)
        } else {
            XCTFail()
        }
    }

    private func completeSession(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> ClientResult {

        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")

        var capturedResult: ClientResult!

        sut.get(from: .anyURL()) { result in
            capturedResult = result
                exp.fulfill()
            }

        wait(for: [exp], timeout: 1.0)
        return capturedResult
    }
    // MARK: - Test Helpers
    /// Factory method to create client, to protect our test from unrelated changes, If we introduced decencies to the client type so the tests that don't care about this decencies can just call this method and we can add default values to this factory method so only the test cases that wants to send specific values for the decency can send it, other can depend on the default values that are supported by this factory method.
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut)
        return sut
    }
}



// We will use the recommended way from Apple to test network requests, which is using the URLProtocol approach, so we will be the network system, that will handle the URL requests protocols.
private class URLProtocolStub: URLProtocol {

    struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?

        init(data: Data?, response:URLResponse?, error: Error? = nil) {
            self.data = data
            self.response = response
            self.error = error
        }
    }

    // So this is the control point for us, we check against this object, the type of this control object contain all the data that can be returned from make a request using a session, which is Data?, Response?, and Error?
    // So we can stub the session, or complete the session with the result that we want to test case it, and check against it here, Like a logger 🪵
    static var stub: Stub?

    /// I don't guarantee the order of the call methods, I don't know when to assert, thats why we pay pass that by using closures, so we can start asserting when the closure reply.
    static var didRequestClosure: ((URLRequest) -> Void)?

    /// The Stub Control method
    static func stub(data: Data?, response: URLResponse?, error: Error?) { // shortcut to mock wanted behaviour 😉
        stub = Stub(data: data, response: response, error: error)
    }

    static func startInterceptingRequests(){
        URLProtocol.registerClass(self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(self)
        stub = nil
        Self.didRequestClosure = nil
    }

    static func observeRequests(_ observeRequest: @escaping (URLRequest) -> Void) -> Void  {
        didRequestClosure = observeRequest
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let requestObserver = URLProtocolStub.didRequestClosure {
            client?.urlProtocolDidFinishLoading(self)
            return requestObserver(request)
        }
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



private extension URL {
    static func anyURL() -> URL {
        let url = URL(string: "http://given-url.com")!
        return url
    }
}


private extension NSError {
    static let any = NSError(domain: "any error", code: 0)
}
