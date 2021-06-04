//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 04.06.21.
//

import Foundation

final class FeedItemMapper {

    static let OK_200: Int = 200

    static func map (_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map { $0.item }
    }

    private struct Root: Decodable {
        let items: [Item]
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
