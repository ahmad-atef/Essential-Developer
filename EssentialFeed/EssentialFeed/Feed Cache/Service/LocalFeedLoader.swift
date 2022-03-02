public class LocalFeedLoader: CacheFeedLoader {
    private let store: FeedStore
    private let currentDate: Date // start point to compare 🧑‍⚖️
    private let calendar = Calendar(identifier: .gregorian)

    public init(_ feedStore: FeedStore, currentDate: Date) {
        self.store = feedStore
        self.currentDate = currentDate
    }

    private var maxCacheAgeInDays: Int { 7 }

    private func validate(_ timeStamp: Date) -> Bool {
        guard let daysDiff = calendar.dateComponents([.day], from: timeStamp, to: currentDate).day else { return false }
        return daysDiff < maxCacheAgeInDays
    }
}

// MARK: Saving
extension LocalFeedLoader {
    public func save(items: [FeedItem], completion: @escaping (CacheFeedResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items.map(LocalFeedItem.init), with: completion)
            }
        }
    }

    private func cache(_ items: [LocalFeedItem], with completion: @escaping (CacheFeedResult) -> Void) {
        store.insertFeed(items, timeStamp: currentDate) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

// MARK: Loading
extension LocalFeedLoader {
    public func loadItems(completion: @escaping (LocalFeedResult) -> Void) {
        store.retrieveFeed { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .found(let items, let timeStamp) where self.validate(timeStamp):
                completion(.success(items))
            case .empty, .found: // Store contains expired items.
                completion(.success([]))
            }
        }
    }
}

// MARK: Validation
extension LocalFeedLoader {
    public func validateCache() {
        store.retrieveFeed { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                self.store.deleteCachedFeed(completion: { _ in })
            case .found(_ , let timeStamp) where !self.validate(timeStamp):
                self.store.deleteCachedFeed(completion: { _ in })
            case .empty, .found:
                break;
            }
        }
    }
}
