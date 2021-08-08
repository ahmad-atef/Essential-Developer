//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 14.05.21.
//

public final class RemoteFeedLoader: FeedLoader {

    /// Remote Feed Loader domain Errors.
    // no problem to define your own error type, but at the end we will end up with Error
    // i.e the interface API should return <FeedItem, Error> <- not Domain Error but normal generic error.

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


    public func loadFeed(completion: @escaping (FeedLoaderResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let _ = self else { return }
            switch result {
            case .success((let data, let response)): // Founded Data + Response
                completion(Self.map(data, from: response))
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }

    private static func map(_ data: Data, from response: HTTPURLResponse) -> FeedLoaderResult {
        do {
            let remoteFeedItems = try FeedItemMapper.map(data, response)
            return .success(remoteFeedItems.toItems())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toItems() -> [FeedItem] {
        return map (FeedItem.init)
    }
}

private extension FeedItem {
    init(_ remoteFeedItem: RemoteFeedItem) {
        self.init(
            id: remoteFeedItem.id,
            description: remoteFeedItem.description,
            location: remoteFeedItem.location,
            imageURL: remoteFeedItem.image
        )
    }
}
