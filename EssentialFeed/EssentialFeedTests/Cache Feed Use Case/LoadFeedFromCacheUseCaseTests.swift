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

    // when invoking `save` command, I should request from feed-store to delete
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
