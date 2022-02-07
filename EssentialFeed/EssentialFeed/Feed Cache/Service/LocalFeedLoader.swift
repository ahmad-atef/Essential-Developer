public class LocalFeedLoader: CacheFeedLoader {
    private let store: FeedStore
    private let currentDate: Date // start point to compare 🧑‍⚖️
    private let calendar = Calendar(identifier: .gregorian)

    public init(_ feedStore: FeedStore, currentDate: Date) {
        self.store = feedStore
        self.currentDate = currentDate
    }

    /// Simply what this API does is, given you want to save some items / response
    /// it will try first to remove the cached response, if that succeeded...
    ///  it will try to save the new items / response, if that succeeded
    /// then operation done successfully

    /// Save = ☑️ Delete + ☑️ Insert
    /// Save = Delete (❌,☑️) -> Insert (❌,☑️)

    // LocalFeedLoader Must work with FeedItem model, as it receives FeedItem from the other components e.g RemoteFeedLoader, so we should keep the API or the contract clean as it is.
    // But when we save and communicate with FeedStore (the guy who will remove the old cache and insert the new FeedItem, we should add our own DTO thats related to caching module which is `LocalFeedItem`

    public func save(items: [FeedItem], completion: @escaping (CacheFeedResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.insert(items.toLocal(), with: completion)
            }
        }
    }

    //MARK:- Helper method
    private func insert(_ items: [LocalFeedItem], with completion: @escaping (CacheFeedResult) -> Void) {
        store.insertFeed(items, timeStamp: currentDate) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] { map { LocalFeedItem($0) } }
}


extension LocalFeedLoader {
    /// Use this command to load Feed from cache, the cached Feed shouldn't be expired.

    // Query should NOT have a side effect, `retrieve` or `load` should only Load, i.e no other logic should be included like cache invalidation or anything else, this is whats called CQS: Command Query Separation 👌
    public func loadItems(completion: @escaping (LocalFeedResult) -> Void) {
        store.retrieveFeed { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.store.deleteCachedFeed(completion: { _ in })
                completion(.failure(error))
            case .found(let items, let timeStamp) where self.cacheIsNotExpired(timeStamp):
                completion(.success(items))
            case .empty:
                completion(.success([]))
            case .found: // Store contains expired items.
                self.store.deleteCachedFeed(completion: { _ in })
                completion(.success([]))
            }
        }
    }
    
    private func cacheIsNotExpired(_ timeStamp: Date) -> Bool {
        guard let daysDiff = calendar.dateComponents([.day], from: timeStamp, to: currentDate).day else { return false }
        return daysDiff < 7
    }
}
