public typealias CacheFeedResult = Error?
public typealias LocalFeedResult = Result<[LocalFeedImage], Error>

public protocol CacheFeedLoader {
    func save(items: [FeedImage], completion: @escaping (CacheFeedResult) -> Void)
    func loadItems(completion: @escaping (LocalFeedResult) -> Void )
}
