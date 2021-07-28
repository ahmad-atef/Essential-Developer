//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 16.07.21.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    class LocalFeedLoader {
        let feedStore: FeedStore
        let timeStamp: Date

        init(_ feedStore: FeedStore, timeStamp: Date = .init()) {
            self.feedStore = feedStore
            self.timeStamp = timeStamp
        }

        func save(items: [FeedItem], completion: @escaping (Error?) -> Void) {
            feedStore.removeItems(items) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    completion(error)
                } else {
                    self.feedStore.insertItems(items, timeStamp: self.timeStamp, completion: completion)
                }
            }
        }
    }

    func test_init_doesNotDeleteCacheUponCreation () {
        let store = SpyFeedStore()
        _ = LocalFeedLoader(store)

        XCTAssertEqual(store.deleteCashRequestCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let feedStore = SpyFeedStore()
        let sut = LocalFeedLoader(feedStore)

        sut.save(items: []) { _ in }

        XCTAssertEqual(feedStore.deleteCashRequestCount, 1)
    }
}

private class SpyFeedStore: FeedStore {

    private(set) var deleteCashRequestCount = 0
    

    func removeItems(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        deleteCashRequestCount += 1
    }

    func insertItems(_ items: [FeedItem], timeStamp: Date, completion: @escaping (Error?) -> Void) {

    }

}


protocol FeedStore {
    func removeItems(_ items: [FeedItem], completion: @escaping (Error?) -> Void)
    func insertItems(_ items: [FeedItem], timeStamp: Date, completion: @escaping (Error?) -> Void)
}
