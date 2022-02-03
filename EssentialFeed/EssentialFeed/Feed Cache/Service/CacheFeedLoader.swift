public typealias CacheFeedResult = Error?
public typealias LocalFeedResult = Result<[LocalFeedItem], Error>

public protocol CacheFeedLoader {
    func save(items: [FeedItem], completion: @escaping (CacheFeedResult) -> Void)
    func loadItems(completion: @escaping (LocalFeedResult) -> Void )
}
