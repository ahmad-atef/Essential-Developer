//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 14.05.21.
//

public typealias ClientResult = Result<(Data,HTTPURLResponse), Error>
public typealias LoaderResult = Result<[FeedItem], RemoteFeedLoader.Error>

public protocol HTTPClient {
    func request(from url: URL, completion: @escaping (ClientResult) -> Void)
}

public final class RemoteFeedLoader {

    /// Remote Feed Loader domain Errors.
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (LoaderResult) -> Void) {
        client.request(from: url) { result in
            switch result {
            case .success((let data, let response)):
                do {
                    let result = try FeedItemMapper.map(data, response)
                    completion(.success(result))
                } catch RemoteFeedLoader.Error.connectivity {
                    completion(.failure(.connectivity))
                } catch RemoteFeedLoader.Error.invalidData {
                    completion(.failure(.invalidData))
                } catch {
                    preconditionFailure("Unexpected error!")
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

class FeedItemMapper {

    static let OK_200: Int = 200

    static func map (_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map { $0.item }
    }
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
