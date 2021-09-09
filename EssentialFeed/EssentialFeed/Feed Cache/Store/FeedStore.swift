public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (CacheFeedResult) -> Void)
    func insertFeed(_ items: [LocalFeedItem], timeStamp: Date, completion: @escaping (CacheFeedResult) -> Void)
    func retrieveFeed(completion: @escaping (Result<LocalFeedItem, Error>) -> Void)
}
