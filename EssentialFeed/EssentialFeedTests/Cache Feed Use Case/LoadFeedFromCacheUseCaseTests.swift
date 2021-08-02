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

    /// Simply what this API does is, given you want to save some items / response
    /// it will try first to remove the cached response, if that succeeded...
    ///  it will try to save the new items / response, if that succeeded
    /// then operation done successfully

    /// Save = Delete (❌,☑️) -> Insert (❌,☑️)

    func save(items: [FeedItem], completion: @escaping (Error?) -> Void) {
        feedStore.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                self.feedStore.insertFeed(items, completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

class LoadFeedFromCacheUseCaseTests: XCTestCase {


    func test_init_doesNotDeleteCacheUponCreation () {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.operations, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(items: []) { _ in }

        XCTAssertEqual(store.operations, [.deletion])
    }

    func test_save_doesNotRequestInsertOnCacheDeletionError() {
        let (sut, store) = makeSUT()

        sut.save(items: []) { _ in }
        store.completeDeletionWithError(.anyNSError)

        XCTAssertEqual(store.operations, [.deletion])
    }

    func test_save_requestDeletionThenInsertionOnCacheDeletionSuccess() {
        let (sut, store) = makeSUT()

        let items: [FeedItem] = [.unique, .unique]
        sut.save(items: items) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.operations.count, 2)
        XCTAssertEqual(store.operations, [.deletion, .insertion(items)])
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
        let (sut, feedStore) = makeSUT()

        let exp = expectation(description: "wait for all operations to finish")
        sut.save(items: [.unique]) { error in
            XCTAssertNil(error, "Save should success when Deletion and Insertion succeed")
            exp.fulfill()
        }

        feedStore.completeDeletionSuccessfully()
        feedStore.completeInsertionSuccessfully()

        wait(for: [exp], timeout: 1.0)
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

    enum Operation: Equatable {
        case deletion
        case insertion(_ items: [FeedItem])
    }

    private(set) var operations = [Operation]()
    private(set) var deletions = [(Error?) -> Void]()
    private(set) var insertions = [(Error?) -> Void]()


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


    func insertFeed(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        operations.append(.insertion(items))
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
