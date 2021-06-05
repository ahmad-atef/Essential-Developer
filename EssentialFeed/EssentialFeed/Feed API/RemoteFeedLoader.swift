//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 14.05.21.
//

public typealias LoaderResult = Result<[FeedItem], RemoteFeedLoader.Error>

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
        client.request(from: url) { [weak self] result in
            guard let _ = self else { return }
            switch result {
            case .success((let data, let response)):
                completion(FeedItemMapper.map(data, response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
