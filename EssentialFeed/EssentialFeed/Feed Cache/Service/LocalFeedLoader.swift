/*
--------------------------------------------------------------
 Narrative:
--------------------------------------------------------------
As an online customer
I want the app to automatically load my latest image feed
So I can always enjoy the newest images of my friends
--------------------------------------------------------------
 Scenarios (Acceptance criteria)
--------------------------------------------------------------
Given the customer has connectivity
When the customer requests to see their feed
Then the app should display the latest feed from remote
And replace the cache with the new feed

*/

public class LocalFeedLoader: CacheFeedLoader {
    private let store: FeedStore
    private let currentDate: Date


    public init(_ feedStore: FeedStore, currentDate: Date) {
        self.store = feedStore
        self.currentDate = currentDate
    }

    /// Simply what this API does is, given you want to save some items / response
    /// it will try first to remove the cached response, if that succeeded...
    ///  it will try to save the new items / response, if that succeeded
    /// then operation done successfully

    /// Save = ☑️ Delete + ☑️ Insert
    /// Save = Delete (❌,☑️) -> Insert (❌,☑️)

    // LocalFeedLoader Must work with FeedItem model, as it receives FeedItem from the other components e.g RemoteFeedLoader, so we should keep the API or the contract clean as it is.
    // But when we save and communicate with FeedStore (the guy who will remove the old cache and insert the new FeedItem, we should add our own DTO thats related to caching module which is `LocalFeedItem`

    public func save(items: [FeedItem], completion: @escaping (CacheFeedResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.insert(items.toLocal(), with: completion)
            }
        }
    }

    //MARK:- Helper method
    private func insert(_ items: [LocalFeedItem], with completion: @escaping (CacheFeedResult) -> Void) {
        store.insertFeed(items, timeStamp: currentDate) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] { map { LocalFeedItem($0) } }
}



/*
--------------------------------------------------------------
Narrative:
--------------------------------------------------------------
As an offline customer
I want the app to show the latest saved version of my image feed
So I can always enjoy images of my friends

--------------------------------------------------------------
Scenarios (Acceptance criteria)
--------------------------------------------------------------
Given the customer doesn't have connectivity
And there’s a cached version of the feed
And the cache is less than seven days old
When the customer requests to see the feed
Then the app should display the latest feed saved

Given the customer doesn't have connectivity
And there’s a cached version of the feed
And the cache is seven days old or more
When the customer requests to see the feed
Then the app should display an error message

Given the customer doesn't have connectivity
And the cache is empty
When the customer requests to see the feed
Then the app should display an error message

*/


extension LocalFeedLoader {
    /// Use this command to load Feed from cache, the cached Feed shouldn't be expired.
    public func loadItems(completion: @escaping (Result<LocalFeedItem, Error>) -> Void) {
        store.retrieveFeed(completion: completion)
    }
}
