public extension LocalFeedImage {
    init(_ feedItem: FeedImage) {
        self.init(
            id: feedItem.id,
            description: feedItem.description,
            location: feedItem.location,
            imageURL: feedItem.imageURL
        )
    }
}
