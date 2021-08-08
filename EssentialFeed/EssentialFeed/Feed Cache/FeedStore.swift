public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (LocalFeedLoader.SaveResult) -> Void)
    func insertFeed(_ items: [FeedItem], timeStamp: Date, completion: @escaping (LocalFeedLoader.SaveResult) -> Void)
}
