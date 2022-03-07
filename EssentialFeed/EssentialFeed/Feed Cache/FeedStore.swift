import Foundation

public enum RetrieveFeedResult {
    case empty
    case failure(Error)
    case found([LocalFeedImage], Date)
}

public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (CacheFeedResult) -> Void)
    func insertFeed(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping (CacheFeedResult) -> Void)
    func retrieveFeed(completion: @escaping (RetrieveFeedResult) -> Void)
}
