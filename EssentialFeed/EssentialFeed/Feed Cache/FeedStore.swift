public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping (CacheFeedResult) -> Void)
    func insertFeed(_ items: [LocalFeedItem], timeStamp: Date, completion: @escaping (CacheFeedResult) -> Void)
}

// Mirror for the `FeedItem` but for Local representation.
public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL

    public init(id: UUID, description: String?, location: String?, imageURL: URL) {
        self.id = id
        self.imageURL = imageURL
        self.description = description
        self.location = location
    }
}
