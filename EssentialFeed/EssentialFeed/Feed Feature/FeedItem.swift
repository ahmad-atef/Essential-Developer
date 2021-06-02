public struct FeedItem: Equatable {

    public init(id: UUID, description: String?, location: String?, imageURL: URL) {
        self.id = id
        self.imageURL = imageURL
        self.description = description
        self.location = location
    }

    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
}
