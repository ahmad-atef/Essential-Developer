//
//  SpyStore.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 09.09.21.
//

import Foundation
import EssentialFeed

final class SpyFeedStore: FeedStore {

    enum Operation: Equatable {
        case deletion
        case insertion([LocalFeedItem], Date)
        case retrieval
    }

    private(set) var operations = [Operation]()

    private var deletions = [(Error?) -> Void]()
    private var insertions = [(Error?) -> Void]()
    private var retrievals = [(RetrieveFeedResult) -> Void]()


    // Delete operations
    func deleteCachedFeed(completion: @escaping (Error?) -> Void) {
        deletions.append(completion)
        operations.append(.deletion)
    }

    /// ⚡️ publisher to mirror the production behaviour,
    /// 🙉 Someone is listing to the operation (subscriber)
    /// Here we are sending events to them 🚀

    func completeDeletionWithError(_ error: NSError, at index: Int = 0) {
        deletions[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletions[index](nil)
    }


    // Insert Operations
    func insertFeed(_ items: [LocalFeedItem], timeStamp: Date, completion: @escaping (Error?) -> Void) {
        operations.append(.insertion(items, timeStamp))
        insertions.append(completion)
    }

    func completeInsertionWithError(_ error: NSError, at index: Int = 0) {
        insertions[index](error)
    }

    func completeInsertionSuccessfully (at index: Int = 0) {
        insertions[index](nil)
    }

    // Retrieve Operations
    func retrieveFeed(completion: @escaping (RetrieveFeedResult) -> Void) {
        operations.append(.retrieval)
        retrievals.append(completion)
    }

    func completeRetrievalWithError(_ error: NSError, at index: Int = 0) {
        retrievals[index](.failure(error))
    }

    func completeRetrievalWithEmpty(at index: Int = 0) {
        retrievals[index](.empty)
    }

    func completeRetrievalSuccessfullyWithItems(_ items: [LocalFeedItem], timeStamp: Date = Date(), at index: Int = 0) {
        retrievals[index](.found(items, timeStamp))
    }
}
