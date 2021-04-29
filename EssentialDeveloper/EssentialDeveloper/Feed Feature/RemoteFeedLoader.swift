//
//  RemoteFeedLoader.swift
//  EssentialDeveloper
//
//  Created by Ahmed Atef Ali Ahmed on 23.04.21.
//


struct RemoteFeedLoader: FeedLoader {
    func loadFeed(completion: ([FeedItem]) -> ()) {
        completion(
            [
                .remote,
                .remote
            ]
        )
    }
}


private extension FeedItem {
    static let remote = FeedItem()
}
