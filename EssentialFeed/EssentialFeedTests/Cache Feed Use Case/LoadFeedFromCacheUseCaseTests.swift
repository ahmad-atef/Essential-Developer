//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 16.07.21.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    let feedStore: FeedStore
    let timeStamp: Date

    init(_ feedStore: FeedStore, timeStamp: Date = .init()) {
        self.feedStore = feedStore
        self.timeStamp = timeStamp
    }

    func save(items: [FeedItem]) {
        feedStore.deleteCachedFeed()
    }
}

class LoadFeedFromCacheUseCaseTests: XCTestCase {


    func test_init_doesNotDeleteCacheUponCreation () {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.deleteCacheCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(items: [])

        XCTAssertEqual(store.deleteCacheCount, 1)
    }

    func test_save_doesNotRequestInsertOnCacheDeletionError() {
        let (sut, store) = makeSUT()

        sut.save(items: [])
        store.completeDeletionWithError(.anyNSError)

        XCTAssertEqual(store.insertionCacheCount, 0)
    }

    func test_save_requestsInsertionOnCacheDeletionSuccess() {
        let (sut, store) = makeSUT()

        sut.save(items: [])
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.insertionCacheCount, 1)
    }

    private func makeSUT(_ file: StaticString = #filePath, line: UInt = #line) ->(localFeedLoader: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}

class FeedStore {
    private (set) var deleteCacheCount = 0
    private (set) var insertionCacheCount = 0

    func deleteCachedFeed() {
        deleteCacheCount += 1
    }

    func completeDeletionWithError(_ error: NSError) {

    }

    func completeDeletionSuccessfully() {
        insertionCacheCount += 1
    }
}

private extension NSError{
    static let anyNSError = NSError(domain: "any error", code: 0)
}
