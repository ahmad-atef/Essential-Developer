//
//  LoadFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 09.09.21.
//

import XCTest
import EssentialFeed

final class LoadFromCacheUseCaseTests: XCTestCase {

    func testLoadRequestInsertOperation() {
        let (service, store) = makeSUT()

        service.loadItems { _ in }

        XCTAssertEqual(store.operations, [.retrieval])
    }

    func testLoadCommandFailsWhenStoreFailsToRetrieve() {
        let (service, store) = makeSUT()

        var receivedError: NSError?
        let expectation = expectation(description: "wait for completion")

        service.loadItems { result in
            guard case .failure(let error) = result else {
                XCTFail()
                preconditionFailure()
            }
            receivedError = error as NSError
            expectation.fulfill()
        }
        
        store.completeRetrievalWithError(.anyNSError)
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedError, .anyNSError)
    }
}

extension LoadFromCacheUseCaseTests {
    private func makeSUT(currentDate: Date  = .init(), _ file: StaticString = #filePath, line: UInt = #line) ->(localFeedLoader: LocalFeedLoader, store: SpyFeedStore) {
        let store = SpyFeedStore()
        let sut = LocalFeedLoader(store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
