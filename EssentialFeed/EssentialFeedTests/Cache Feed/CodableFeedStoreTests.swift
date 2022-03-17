import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {

    class CodableFeedStore {

        private struct Cache: Codable {
            let items: [CodableLocalFeedImage]
            let timeStamp: Date

            var localFeed: [LocalFeedImage] {
                items.map{ $0.localFeedImage }
            }
        }

        private struct CodableLocalFeedImage: Codable {
            public let id: UUID
            public let description: String?
            public let location: String?
            public let imageURL: URL

            init(_ localFeedImage: LocalFeedImage) {
                self.id = localFeedImage.id
                self.description = localFeedImage.description
                self.location = localFeedImage.location
                self.imageURL = localFeedImage.imageURL
            }

            var localFeedImage: LocalFeedImage {
                .init(id: id, description: description, location: location, imageURL: imageURL)
            }
        }

        private let storeURL: URL

        init(storeURL: URL) {
            self.storeURL = storeURL
        }

        func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
            let encoder = JSONEncoder()
            let encodedData = try! encoder.encode(Cache(items: items.map(CodableLocalFeedImage.init), timeStamp: timeStamp))
            try! encodedData.write(to: storeURL)
            completion(nil)
        }

        func retrieve(completion: @escaping (RetrieveFeedResult) -> Void) {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }
            let decoder = JSONDecoder()
            do {
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.found(cache.localFeed, cache.timeStamp))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Clean any artefact Before/After running the test.
    private func setupEmptyState() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

    override func setUp() {
        super.setUp()
        setupEmptyState()
    }

    override func tearDown() {
        setupEmptyState()
        super.tearDown()
    }

    // retrieve from empty cache delivers empty result.
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }

    // retrieve multiple times from empty cache should return the same empty results each time.
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieveTwice: .empty)
    }

    // retrieve from non empty cache, should return the saved image.
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        // given
        let sut = makeSUT()
        let items: [LocalFeedImage] = [.unique]
        let timeStamp = Date()

        // when
        insert(items, timeStamp: timeStamp, to: sut)

        // then
        expect(sut, toRetrieve: .found(items, timeStamp))
    }

    func test_retrieve_hasNoSideEffectOnNonEmptyCache() {
        // given
        let sut = makeSUT()
        let items: [LocalFeedImage] = [.unique]
        let timeStamp = Date()

        // when
        insert(items, timeStamp: timeStamp, to: sut)

        // then
        expect(sut, toRetrieveTwice: .found(items, timeStamp))
    }

    func test_retrieve_shouldReturnErrorOnError() {
        // given
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        //when
        // make a wrong state to the same place we reading the data from.
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        enum FakeError: Error { case any }
        expect(sut, toRetrieve: .failure(FakeError.any))
    }



    // MARK: Helper methods

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let storeURL = storeURL ?? testSpecificStoreURL()
        let sut = CodableFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func testSpecificStoreURL() -> URL {
        FileManager
            .default
            .urls(for: .cachesDirectory,
                     in: .userDomainMask)
            .first!
            .appendingPathComponent("\(type(of: self)).store")
    }

    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Waiting for cache to retrieve")

        sut.retrieve { retrievedResult in
            switch (retrievedResult, expectedResult) {
            case (.empty, .empty): break
            case (.failure, .failure): break
            case let (.found(retrievedItems, retrievedDate), .found(expectedItems, expectedDate)):
                XCTAssertEqual(retrievedItems, expectedItems)
                XCTAssertEqual(retrievedDate, expectedDate)
            default:
                XCTFail(
                    "Expected to retrieve \(expectedResult), got \(retrievedResult) instead",
                    file: file,
                    line: line
                )
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func insert(_ cache: [LocalFeedImage], timeStamp: Date, to sut: CodableFeedStore) {
        let exp = expectation(description: "Waiting for cache insertion")
        sut.insert(cache, timeStamp: timeStamp) { error in
            XCTAssertNil(error, "Expected feed to be inserted successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
