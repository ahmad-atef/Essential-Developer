public extension LocalFeedItem {
    init(_ feedItem: FeedItem) {
        self.init(
            id: feedItem.id,
            description: feedItem.description,
            location: feedItem.location,
            imageURL: feedItem.imageURL
        )
    }
}
