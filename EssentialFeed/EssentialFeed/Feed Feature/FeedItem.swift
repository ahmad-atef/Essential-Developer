public struct FeedItem: Equatable {

    public init(id: UUID, imageURL: URL, description: String? = nil, location: String? = nil) {
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
        case imageURL = "image"
    }
}
