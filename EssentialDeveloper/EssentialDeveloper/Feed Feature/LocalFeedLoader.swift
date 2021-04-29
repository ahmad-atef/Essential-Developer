//
//  LocalFeedLoader.swift
//  EssentialDeveloper
//
//  Created by Ahmed Atef Ali Ahmed on 23.04.21.
//


struct LocalFeedLoader: FeedLoader {
    func loadFeed(completion: ([FeedItem]) -> ()) {
        completion(
            [
                .local,
                .local,
                .local
            ]
        )
    }
}

private extension FeedItem {
    static let local = FeedItem()
}
