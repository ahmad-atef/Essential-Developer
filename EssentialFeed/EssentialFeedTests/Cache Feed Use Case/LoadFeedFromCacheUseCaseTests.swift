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
}


protocol FeedStore {
    func removeItems(_ items: [FeedItem], completion: @escaping (Error?) -> Void)
    func insertItems(_ items: [FeedItem], timeStamp: Date, completion: @escaping (Error?) -> Void)
}
