//
//  ValidateCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 07.02.22.
//

import Foundation
import EssentialFeed
import XCTest

final class ValidateCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertTrue(store.operations.isEmpty)
    }

    // MAKR:- Helper Factory method 🏭
    private func makeSUT(currentDate: Date  = .init(), _ file: StaticString = #filePath, line: UInt = #line) ->(localFeedLoader: LocalFeedLoader, store: SpyFeedStore) {
        let store = SpyFeedStore()
        let sut = LocalFeedLoader(store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
