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
