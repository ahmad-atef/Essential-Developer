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
                if response.statusCode == 200,
                   let root = try? JSONDecoder().decode(Root.self, from: data){
                    completion(.success(root.items.map { $0.item }))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
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
    private let id: UUID
    private let description: String?
    private let location: String?
    private let image: URL

    var item: FeedItem {
        .init(
            id: id,
            description: description,
            location: location,
            imageURL: image
        )
    }
}
