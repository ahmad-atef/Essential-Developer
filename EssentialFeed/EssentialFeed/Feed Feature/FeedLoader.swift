//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 29.04.21.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case fail(Error)
}

protocol FeedLoader {
    func loadFeed(completion: @escaping (LoadFeedResult) -> Void)
}
