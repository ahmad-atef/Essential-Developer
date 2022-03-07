import Foundation

public enum RetrieveFeedResult {
    case empty
    case failure(Error)
    case found([LocalFeedImage], Date)
}

public protocol FeedStore {

    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrieveFeedResult) -> Void

    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insertFeed(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}
