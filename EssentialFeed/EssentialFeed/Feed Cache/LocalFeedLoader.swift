//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 05.08.21.
//

public typealias CacheFeedResult = Error?

public protocol CacheFeedLoader {
    func save(items: [FeedItem], completion: @escaping (CacheFeedResult) -> Void)
}

public class LocalFeedLoader: CacheFeedLoader {
    private let feedStore: FeedStore
    private let currentDate: Date


    public init(_ feedStore: FeedStore, currentDate: Date) {
        self.feedStore = feedStore
        self.currentDate = currentDate
    }

    /// Simply what this API does is, given you want to save some items / response
    /// it will try first to remove the cached response, if that succeeded...
    ///  it will try to save the new items / response, if that succeeded
    /// then operation done successfully

    /// Save = ☑️ Delete + ☑️ Insert
    /// Save = Delete (❌,☑️) -> Insert (❌,☑️)

    public func save(items: [FeedItem], completion: @escaping (CacheFeedResult) -> Void) {
        feedStore.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.insert(items, with: completion)
            }
        }
    }

    //MARK:- Helper method
    private func insert(_ items: [FeedItem], with completion: @escaping (CacheFeedResult) -> Void) {
        feedStore.insertFeed(items, timeStamp: currentDate) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}
