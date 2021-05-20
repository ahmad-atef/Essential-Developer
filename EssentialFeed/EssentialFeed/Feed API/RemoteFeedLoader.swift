//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 14.05.21.
//


public final class RemoteFeedLoader {

    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public enum Error: Swift.Error {
        case connectivity
    }

    public func load(completion: (Error) -> Void = { _ in }) {
        client.request(from: url, completion: { error in
            completion(.connectivity)
        })
    }
}

public protocol HTTPClient {
    func request(from url: URL, completion: (Error) -> Void)
}
