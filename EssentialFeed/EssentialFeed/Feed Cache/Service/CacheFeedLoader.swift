public typealias CacheFeedResult = Error?

public protocol CacheFeedLoader {
    func save(items: [FeedItem], completion: @escaping (CacheFeedResult) -> Void)
    func loadItems(completion: @escaping (Result<FeedItem, Error>) -> Void )
}
