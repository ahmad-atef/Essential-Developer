//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 04.06.21.
//

final class FeedItemMapper {

    private static let OK_200: Int = 200

    static func map (_ data: Data, _ response: HTTPURLResponse) -> LoaderResult {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        return (.success(root.feed))
    }

    private struct Root: Decodable {
        let items: [Item]
        var feed: [ FeedItem ] {
            items.map( { $0.item } )
        }
    }

    // Separate module that represents the API version of the FeedItem 👌🤩
    // and keep that key path knowledge in that domain
    // then you can convert it into the general shared module FeedItem

    /// Transitional representation of FeedItem that specific of the API module.
    private struct Item: Decodable {
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
}
