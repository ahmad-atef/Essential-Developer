import Foundation

/// Transitional representation of FeedItem that specific of the API module.
/// DTO for Remote Feed representation.
struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL

    var item: FeedImage {
        .init(
            id: id,
            description: description,
            location: location,
            imageURL: image
        )
    }
}
