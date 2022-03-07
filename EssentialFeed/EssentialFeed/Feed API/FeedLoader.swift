import Foundation

public typealias FeedLoaderResult = Result<[FeedImage], Error>

protocol FeedLoader {
    func loadFeed(completion: @escaping (FeedLoaderResult) -> Void)
}

