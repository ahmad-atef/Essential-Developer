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
            case .success((let data, _)):
                data.isValidJSON ? completion(.success([])) : completion(.failure(.invalidData))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private extension Data {
    var isValidJSON: Bool {
        guard (try? JSONSerialization.jsonObject(with: self)) != nil else { return false }
        return true
    }
}


