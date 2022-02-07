//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 16.07.21.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {

    // no save command executed, I shouldn't do anything with the feed store
    // up on creation
    func test_init_doesNotMessageStoreUponCreation () {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.operations, [])
    }

    // when invoking `save` command, I MUST `delete` the previous image first.
    // save request delete
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(items: []) { _ in }

        XCTAssertEqual(store.operations, [.deletion])
    }

    // when saving and the `delete` command fails,
    // I shouldn't insert anything
    // + I should receive deletion failure error
    // on delete fail I should receive delete error
    // test_save_failsOnDeletionError
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        var expectedError: NSError = .anyNSError
        let exp = expectation(description: "")

        sut.save(items: []) { error in
            expectedError = error! as NSError
            exp.fulfill()
        }
        store.completeDeletionWithError(.anyNSError)
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(store.operations, [.deletion])
        XCTAssertEqual(expectedError, .anyNSError)
    }

    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: timestamp)

        let items = uniqueItems()
        sut.save(items: items.model) { _ in } // So we save [FeedItem]
        store.completeDeletionSuccessfully()

        // but we expect feedStore to insert [LocalFeedItem]
        XCTAssertEqual(store.operations, [.deletion, .insertion(items.local, timestamp)])
    }

    private func uniqueItems() -> (model: [FeedItem], local: [LocalFeedItem]) {
        let items: [FeedItem] = [.unique, .unique]
        let localFeedItems: [LocalFeedItem] = items.map { LocalFeedItem($0) }
        return(items, localFeedItems)
    }

    // insert failure
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()

        let expectedError: NSError = .anyNSError
        let exp = expectation(description: "wait for insertion to complete")

        sut.save(items: []) { error in
            XCTAssertEqual(error as NSError?, expectedError)
            exp.fulfill()
        }

        store.completeDeletionSuccessfully()
        store.completeInsertionWithError(.anyNSError)

        wait(for: [exp], timeout: 1.0)
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let timeStamp = Date()
        let (sut, feedStore) = makeSUT(currentDate: timeStamp)

        let exp = expectation(description: "wait for all operations to finish")
        sut.save(items: uniqueItems().model) { error in
            XCTAssertNil(error, "Save should success when Deletion and Insertion succeed")
            exp.fulfill()
        }

        feedStore.completeDeletionSuccessfully()
        feedStore.completeInsertionSuccessfully()

        wait(for: [exp], timeout: 1.0)
    }

    func test_load_hasNoSideEffectsOnRetrievalError() {

        // Given
        let (sut, store) = makeSUT()

        // When
        sut.loadItems { _ in }
        store.completeRetrievalWithError(.anyNSError)

        // Then
        XCTAssertEqual(store.operations, [.retrieval])
    }

    func test_load_hasNoSideEffectOnEmptyCache() {
        // Given
        let (sut, store) = makeSUT()

        // When
        sut.loadItems { _ in }
        store.completeRetrievalWithEmpty()

        // Then
        XCTAssertEqual(store.operations, [.retrieval])
    }

    // If cache is valid (not expired), then the load command shouldn't Clear cache, but do Insert operation.
    func test_load_shouldNotClearValidCache() {

        // Given
        let currentDate = Date()
        let (sut, store) = makeSUT(currentDate: currentDate)
        let validTimestamp = currentDate.changeTime(byAddingDays: -7, seconds: 1) // one second after seven days old.
        let localFeedItem: LocalFeedItem = .unique

        sut.loadItems(completion: { _ in })
        store.completeRetrievalSuccessfullyWithItems([localFeedItem], timeStamp: validTimestamp)

        XCTAssertEqual(store.operations, [.retrieval])
    }

    // If the cache is seven days old
    // then, the local feed loader should Delete the cache.
    // i.e the store dependency should receive a Delete operation.
    func test_load_shouldDelteCacheIfFoundInvalidCache() {
        // Given
        let currentDate = Date()
        let (sut, store) = makeSUT(currentDate: currentDate)

        let invalidInsertion: (items: [LocalFeedItem], timeStamp: Date) = ([.unique], currentDate.changeTime(byAddingDays: -7))

        sut.loadItems(completion: { _ in })
        store.completeRetrievalSuccessfullyWithItems(invalidInsertion.items, timeStamp: invalidInsertion.timeStamp)
        XCTAssertEqual(store.operations, [.retrieval, .deletion])
    }

    // If the cache is more than seven days old
    // then, the local feed loader should Delete the cache.
    // i.e the store dependency should receive a Delete operation.
    func test_load_shouldDeleteCacheIfFoundMoreThanSevenDaysOldCache() {
        // Given
        let currentDate = Date()
        let (sut, store) = makeSUT(currentDate: currentDate)

        let invalidInsertion: (items: [LocalFeedItem], timeStamp: Date) = ([.unique], currentDate.changeTime(byAddingDays: -7, seconds: -1)) // 7 days + 1 second in the past.
        sut.loadItems(completion: { _ in })
        store.completeRetrievalSuccessfullyWithItems(invalidInsertion.items, timeStamp: invalidInsertion.timeStamp)
        XCTAssertEqual(store.operations, [.retrieval, .deletion])
    }

    // From memory management wise, if the local feed loader has been removed from memoer
    // then, we should NOT receive any results when calling the load command.
    // other wise, that means we have memory leaks.
    // If the SUT has been removed from memory, and EVEN IF the store completed retrieval successfully
    // we shouldn't receive results from the closure, as the loader was already deallocated from memory.

    // TLDR: We shouldn't receive results unless the loader exist in memory, if the loader was removed from memory, don't deliver anything please, otherwise, that means in production we will have a memory leaks.
    
    func test_load_doesNotDeliverAnyResultsAfterLoadHasBeenDeallocated() {
        let store = SpyFeedStore()
        var localFeedLoad: LocalFeedLoader? = LocalFeedLoader(store, currentDate: .init())
        var receivedResults: [LocalFeedResult] = []

        localFeedLoad?.loadItems { receivedResults.append($0) }

        localFeedLoad = nil
        store.completeRetrievalWithEmpty()
        XCTAssertTrue(receivedResults.isEmpty)
    }

    func test_deallocation_behavior_onDeleteCacheError() {
        let feedStore = SpyFeedStore()
        var localFeedLoader: LocalFeedLoader? = .init(feedStore, currentDate: .init())
        var capturedResults = [Error?]()

        localFeedLoader?.save(items: [], completion: { error in
            capturedResults.append(error)
        })

        localFeedLoader = nil
        feedStore.completeDeletionWithError(.anyNSError)

        // notice here ☝️, we don't need to have expectations and wait for it until its getting fulfilled, because we control the completion i.e we own the complete time, we control the moment we execute the completion and update the waiting completion block, its like you are the framework and you say I know when I will update my clients because I'm the framework and I know when I will do things and then I will notify my clients in the right moment, here we are the same, we own the moment, we control the execution because we keep a reference to each handler (because handler at the end of the day is a variable with a function signature, so we easily can call / execute the function and make the action 🏄, and then clients will be notified, so I don't need here to wait (even I can definitely do) because I control the execution in my hand, so the code become now `as` its running sequential on one thread not in multiple threads, thats the reason we don't have expectations here as usual with the async work :)

        XCTAssertTrue(capturedResults.isEmpty)
    }


    func test_deallocation_behavior_onDeleteCacheSuccessButInsertionFails() {
        let feedStore = SpyFeedStore()
        var localFeedLoader: LocalFeedLoader? = .init(feedStore, currentDate: .init())
        var capturedResults = [Error?]()

        localFeedLoader?.save(items: [], completion: { error in
            capturedResults.append(error)
        })

        feedStore.completeDeletionSuccessfully()
        localFeedLoader = nil
        feedStore.completeInsertionWithError(.anyNSError)

        XCTAssertTrue(capturedResults.isEmpty)
    }


    private func makeSUT(currentDate: Date  = .init(), _ file: StaticString = #filePath, line: UInt = #line) ->(localFeedLoader: LocalFeedLoader, store: SpyFeedStore) {
        let store = SpyFeedStore()
        let sut = LocalFeedLoader(store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
