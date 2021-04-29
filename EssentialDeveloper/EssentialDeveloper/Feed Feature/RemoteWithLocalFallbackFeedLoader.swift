//
//  RemoteLocalFallbackLoader.swift
//  EssentialDeveloper
//
//  Created by Ahmed Atef Ali Ahmed on 23.04.21.
//

struct Reachability {
    static let isNetworkAvailable = false
}

struct RemoteWithLocalFallbackFeedLoader: FeedLoader {

    static let `default` = RemoteWithLocalFallbackFeedLoader()

    private let localFeedLoader = LocalFeedLoader()
    private let remoteFeedLoader = RemoteFeedLoader()

    func loadFeed(completion: @escaping ([FeedItem]) -> ()) {
        if Reachability.isNetworkAvailable {
            remoteFeedLoader.loadFeed(completion: completion)
        } else {
            localFeedLoader.loadFeed(completion: completion)
        }
    }
}
