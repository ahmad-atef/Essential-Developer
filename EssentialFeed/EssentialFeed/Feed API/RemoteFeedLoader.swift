//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 14.05.21.
//

public final class RemoteFeedLoader: FeedLoader {

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


    public func loadFeed(completion: @escaping (FeedLoaderResult) -> Void) {
        client.request(from: url) { [weak self] result in
            guard let _ = self else { return }
            switch result {
            case .success((let data, let response)):
                completion(FeedItemMapper.map(data, response))
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}
