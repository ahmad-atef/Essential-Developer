public typealias CacheFeedResult = Error?
public typealias LoadFeedResult = Result<[LocalFeedItem], Error>

public protocol CacheFeedLoader {
    func save(items: [FeedItem], completion: @escaping (CacheFeedResult) -> Void)
    func loadItems(completion: @escaping (LoadFeedResult) -> Void )
}
