//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 16.07.21.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let feedStore: FeedStore
    private let currentDate: Date

    init(_ feedStore: FeedStore, currentDate: Date) {
        self.feedStore = feedStore
        self.currentDate = currentDate
    }

    /// Simply what this API does is, given you want to save some items / response
    /// it will try first to remove the cached response, if that succeeded...
    ///  it will try to save the new items / response, if that succeeded
    /// then operation done successfully

    /// Save = Delete (❌,☑️) -> Insert (❌,☑️)

    func save(items: [FeedItem], completion: @escaping (Error?) -> Void) {
        feedStore.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                self.feedStore.insertFeed(items, timeStamp: self.currentDate, completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (Error?) -> Void)
    func insertFeed(_ items: [FeedItem], timeStamp: Date, completion: @escaping (Error?) -> Void)
}

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    // no save command executed, I shouldn't do anything with the feed store
    // up on creation
    func test_init_doesNotDeleteCacheUponCreation () {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.operations, [])
    }

    // when invoking `save` command, I should request from feed-store to delete
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(items: []) { _ in }

        XCTAssertEqual(store.operations, [.deletion])
    }

    // when saving but the `delete` command fails, I shouldn't insert anything
    // + I should receive deletion failure error
    func test_save_doesNotRequestInsertOnCacheDeletionError() {
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

    func test_save_requestDeletionThenInsertionOnCacheDeletionSuccess() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: timestamp)

        let items: [FeedItem] = [.unique, .unique]
        sut.save(items: items) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.operations.count, 2)
        XCTAssertEqual(store.operations, [.deletion, .insertion(items, timestamp)])
    }

    func test_save_deleteSuccess_InsertFail() {
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

    func test_save_SuccessOnDeletionInsertionSuccess() {
        let timeStamp = Date()
        let (sut, feedStore) = makeSUT(currentDate: timeStamp)

        let exp = expectation(description: "wait for all operations to finish")
        sut.save(items: [.unique]) { error in
            XCTAssertNil(error, "Save should success when Deletion and Insertion succeed")
            exp.fulfill()
        }

        feedStore.completeDeletionSuccessfully()
        feedStore.completeInsertionSuccessfully()

        wait(for: [exp], timeout: 1.0)
    }



    private func makeSUT(currentDate: Date  = .init(), _ file: StaticString = #filePath, line: UInt = #line) ->(localFeedLoader: LocalFeedLoader, store: SpyFeedStore) {
        let store = SpyFeedStore()
        let sut = LocalFeedLoader(store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}

final class SpyFeedStore: FeedStore {

    enum Operation: Equatable {
        case deletion
        case insertion([FeedItem], Date)
    }

    private(set) var operations = [Operation]()
    private var deletions = [(Error?) -> Void]()
    private var insertions = [(Error?) -> Void]()


    func deleteCachedFeed(completion: @escaping (Error?) -> Void) {
        deletions.append(completion)
        operations.append(.deletion)
    }

    /// ⚡️ publisher to mirror the production behavior,
    /// 🙉 Someone is listing to the operation (subscriber)
    /// Here we are sending events to them 🚀

    func completeDeletionWithError(_ error: NSError, at index: Int = 0) {
        deletions[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletions[index](nil)
    }


    func insertFeed(_ items: [FeedItem], timeStamp: Date, completion: @escaping (Error?) -> Void) {
        operations.append(.insertion(items, timeStamp))
        insertions.append(completion)
    }

    func completeInsertionWithError(_ error: NSError, at index: Int = 0) {
        insertions[index](error)
    }

    func completeInsertionSuccessfully (at index: Int = 0) {
        insertions[index](nil)
    }
}

private extension NSError {
    static let anyNSError = NSError(domain: "any error", code: 0)
}

private extension FeedItem {
    static let unique = FeedItem(
        id: UUID(),
        description: nil,
        location: nil,
        imageURL: .init(string: "https://image-url.com")!)
}
