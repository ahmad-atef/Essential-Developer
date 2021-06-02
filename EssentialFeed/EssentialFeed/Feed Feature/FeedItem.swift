public struct FeedItem: Equatable {

    public init(id: UUID, imageURL: URL, description: String?, location: String?) {
        self.id = id
        self.imageURL = imageURL
        self.description = description
        self.location = location
    }

    public let id: UUID
    public let imageURL: URL
    public let description: String?
    public let location: String?
}

extension FeedItem: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case location
        case description
        case imageURL = "image" // API detail leaking in the module
        // the module should be agnostic about the API module.
        // If we keep the knowledge of the key path in the FeedItem module, maybe we will break another module, like data base loader.
    }
}
