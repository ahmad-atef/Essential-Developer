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

    func test_validate_shouldDeleteCacheOnRetrievalError() {
        let (service, store) = makeSUT()

        service.validateCache()
        store.completeRetrievalWithError(.anyNSError)

        XCTAssertEqual(store.operations, [.retrieval, .deletion])
    }

    func test_validate_shouldNotDeleteCacheOnEmptyCache() {
        let (service, store) = makeSUT()

        service.validateCache()
        store.completeRetrievalWithEmpty()

        XCTAssertEqual(store.operations, [.retrieval])
    }

    func test_valid_shouldNotDeleteCacheOnValidCache() {

        let currentDate = Date()
        let (service, store) = makeSUT(currentDate: currentDate)

        service.validateCache()
        store.completeRetrievalSuccessfullyWithItems([.unique], timeStamp: currentDate.minusFeedCacheMaxAge().adding(seconds: 1))

        XCTAssertEqual(store.operations, [.retrieval])
    }

    func test_valid_shouldDeleteCacheOnJustExpiredCache() {

        let currentDate = Date()
        let (service, store) = makeSUT(currentDate: currentDate)

        let expiredDate = currentDate.minusFeedCacheMaxAge()
        service.validateCache()
        store.completeRetrievalSuccessfullyWithItems([.unique], timeStamp: expiredDate)

        XCTAssertEqual(store.operations, [.retrieval, .deletion])
    }

    func test_valid_shouldDeleteCacheOnExpiredCache() {

        let currentDate = Date()
        let (service, store) = makeSUT(currentDate: currentDate)

        let expiredDate = currentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        service.validateCache()
        store.completeRetrievalSuccessfullyWithItems([.unique], timeStamp: expiredDate)

        XCTAssertEqual(store.operations, [.retrieval, .deletion])
    }

    func test_valid_shouldNotClearCacheIfServiceHasBeenRemoved() {
        let spyStore = SpyFeedStore()
        let currentDate = Date()
        var service: LocalFeedLoader? = LocalFeedLoader(spyStore, currentDate: currentDate)

        service?.validateCache()

        service = nil
        spyStore.completeRetrievalWithError(.anyNSError)

        XCTAssertEqual(spyStore.operations, [.retrieval])
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
