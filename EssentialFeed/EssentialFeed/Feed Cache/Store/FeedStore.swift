public enum RetrieveFeedResult {
    case empty
    case failure(Error)
    case found(items: [LocalFeedItem], timeStamped: Date)
}

public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (CacheFeedResult) -> Void)
    func insertFeed(_ items: [LocalFeedItem], timeStamp: Date, completion: @escaping (CacheFeedResult) -> Void)
    func retrieveFeed(completion: @escaping (RetrieveFeedResult) -> Void)
}
