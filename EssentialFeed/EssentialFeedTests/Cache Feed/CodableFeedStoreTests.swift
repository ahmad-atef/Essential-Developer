import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {

    class CodableFeedStore {

        private struct Cache: Codable {
            let items: [LocalFeedImage]
            let timeStamp: Date
        }

        private let storeURL: URL = FileManager.default.urls(for: .documentDirectory,
                                                                in: .userDomainMask)
            .first!.appendingPathComponent("image-feed.store")

        func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
            let encoder = JSONEncoder()
            let encodedData = try! encoder.encode(Cache(items: items, timeStamp: timeStamp))
            try! encodedData.write(to: storeURL)
            completion(nil)
        }

        func retrieve(completion: @escaping (RetrieveFeedResult) -> Void) {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }
            let decoder = JSONDecoder()
            let cache = try! decoder.decode(Cache.self, from: data)
            completion(.found(cache.items, cache.timeStamp))
        }
    }

    override func setUp() {
        super.setUp()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL) // clean any artefact before starting any test.
    }

    override func tearDown() {
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL) // clean up any artefact after executing the test. To be a good citizen.
    }

    // retrieve from empty cache delivers empty result.
    func test_retrieve_deliversEmptyResultOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, found \(result)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // retrieve multiple times from empty cache should return the same empty results each time.
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = CodableFeedStore()
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("""
                            Expected retrieving twice from empty cache to deliver empty results,
                            found \(firstResult) and \(secondResult) instead
                            """)
                }
            }
        }

    }

    // retrieve from non empty cache, should return the saved image.
    func test_retrieve_deliversSavedResultsOnNonEmptyCache() {
        // given
        let sut = CodableFeedStore()
        let items: [LocalFeedImage] = [.unique]
        let timeStamp = Date()
        let exp = expectation(description: "Waiting for cache retrieval")

        // when
        sut.insert(items, timeStamp: timeStamp) { error in
            XCTAssertNil(error, "Expected feed to be inserted successfully")
            sut.retrieve { result in
                switch result {
                case .found(let foundItems, let date):
                    XCTAssertEqual(foundItems, items)
                    XCTAssertEqual(timeStamp, date)
                default:
                    XCTFail("Expected to retrieve inserted items, found \(result) instead")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }
}
