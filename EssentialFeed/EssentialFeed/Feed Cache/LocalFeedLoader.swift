import Foundation

// feed cache use case
public class LocalFeedLoader: CacheFeedLoader {
    private let store: FeedStore
    private let currentDate: Date // start point to compare 🧑‍⚖️

    public init(_ feedStore: FeedStore, currentDate: Date) {
        self.store = feedStore
        self.currentDate = currentDate
    }
}

// MARK: Saving
extension LocalFeedLoader {
    public func save(items: [FeedImage], completion: @escaping (CacheFeedResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items.map(LocalFeedImage.init), with: completion)
            }
        }
    }

    private func cache(_ items: [LocalFeedImage], with completion: @escaping (CacheFeedResult) -> Void) {
        store.insert(items, timeStamp: currentDate) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

// MARK: Loading
extension LocalFeedLoader {
    public func loadItems(completion: @escaping (LocalFeedResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .found(let items, let timeStamp) where FeedCachePolicy.validate(timeStamp, against: self.currentDate):
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
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                self.store.deleteCachedFeed(completion: { _ in })
            case .found(_ , let timeStamp) where !FeedCachePolicy .validate(timeStamp, against: self.currentDate):
                self.store.deleteCachedFeed(completion: { _ in })
            case .empty, .found:
                break;
            }
        }
    }
}
