//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 04.06.21.
//

final class FeedItemMapper {

    private static let OK_200: Int = 200

    // tries to map to RemoteFeedItem from data, response :)

    static func map (_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return root.items
    }

    // Separate module that represents the API version of the FeedItem 👌🤩
    // and keep that key path knowledge in that domain
    // then you can convert it into the general shared module FeedItem
    // so instead of ImageURL in the generic module (FeedItem) which is right from the naming point of view, as ImageURL describes exactly what is that
    // The API replied with image only 🥲
    // So no problem, will keep the right naming in the generic domain FeedItem, and make a private type in the middle to do that ugly naming for us, with out polluting the generic type 😼

    // we created this private struct just for one reason, to mirror the response from the API
    // so we have a Root response which contains a key called `items`
    // each item should be `RemoteFeedItem` 👍
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

}

/// Transitional representation of FeedItem that specific of the API module.
/// DTO for Remote Feed representation.
struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL

    var item: FeedItem {
        .init(
            id: id,
            description: description,
            location: location,
            imageURL: image
        )
    }
}
