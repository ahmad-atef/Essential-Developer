public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (CacheFeedResult) -> Void)
    func insertFeed(_ items: [FeedItem], timeStamp: Date, completion: @escaping (CacheFeedResult) -> Void)
}
