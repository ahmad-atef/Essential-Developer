import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {

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
        // fake as the store url found a courrpted data
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        enum FakeError: Error { case any }
        expect(sut, toRetrieve: .failure(FakeError.any))
    }

    func test_retrieve_hasNoSideEffectOnError() {
        // given
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        //when
        // make a wrong state to the same place we reading the data from.
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        enum FakeError: Error { case any }
        expect(sut, toRetrieveTwice: .failure(FakeError.any))
    }

    func test_insert_overridesPreviousInsertedImageOnNonEmptyCache() {
        let sut = makeSUT()

        let firstInsertionError = insert([.unique], timeStamp: Date(), to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")

        let latestFeed: [LocalFeedImage] = [.unique]
        let latestTimestamp: Date = Date()
        let latestInsertionError = insert(latestFeed, timeStamp: latestTimestamp, to: sut)
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")

        expect(sut, toRetrieve: .found(latestFeed, latestTimestamp))
    }

    func test_insert_shouldDeliverErrorOnInsertionError() {
        // insert to invalid store url will throw this error: "The file couldn’t be saved because URL type invalid isn’t supported."
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed: [LocalFeedImage] = [.unique]
        let timestamp = Date()

        let insertionError = insert(feed, timeStamp: timestamp, to: sut)

        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
        expect(sut, toRetrieve: .empty)

    }


    func test_delete_shouldDeliverEmptyOnEmptyCache() {
        let sut = makeSUT()
        let expectedError = deleteCache(from: sut)

        XCTAssertNil(expectedError, "expected empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }

    func test_delete_shouldDeleteSavedImageOnNonEmptyCache() {
        let sut = makeSUT()

        let items: [LocalFeedImage] = [.unique]
        let timestamp = Date()

        let insertionError = insert(items, timeStamp: timestamp, to: sut)
        XCTAssertNil(insertionError, "expected to in insert to cache successfully!")

        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "expected to in delete cache successfully!")

        expect(sut, toRetrieve: .empty)
    }

    // delete with no-permission store url should fail, e.g: `cache directory`
    func test_delete_shouldDeliverErrorOnDeletionError() {
        let noDeletePermissionURL: URL = .cache
        let sut = makeSUT(storeURL: noDeletePermissionURL)

        let deletionError = deleteCache(from: sut)
        XCTAssertNotNil(deletionError, "expected to fail on delete from cache store url!")
    }

    func test_SUTSideEffects_runSerially() {
        let sut = makeSUT()
        let items: [LocalFeedImage] = [.unique]
        let timestamp = Date()

        let exp1 = expectation(description: "waiting for first operation (insert) to finish")
        var expectations = [XCTestExpectation]()

        sut.insert(items, timeStamp: timestamp, completion: { _ in
            expectations.append(exp1)
            exp1.fulfill()
        })

        let exp2 = expectation(description: "waiting for operation #2 (delete) to finish")
        sut.insert(items, timeStamp: timestamp, completion: { _ in
            expectations.append(exp2)
            exp2.fulfill()
        })

        let exp3 = expectation(description: "waiting for operation#3 (insert) to finish")
        sut.insert(items, timeStamp: timestamp, completion: { _ in
            expectations.append(exp3)
            exp3.fulfill()
        })

        wait(for: [exp1,exp2, exp3], timeout: 5.0)

        XCTAssertEqual(expectations, [exp1, exp2, exp3])

    }
    // MARK: Helper methods

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
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

    private func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Waiting for cache to retrieve")

        sut.retrieve { retrievedResult in
            switch (retrievedResult, expectedResult) {
            case (.empty, .empty): break // ✅
            case (.failure, .failure): break // ✅
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

    @discardableResult
    private func insert(_ cache: [LocalFeedImage], timeStamp: Date, to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Waiting for cache insertion")
        var expectedError: Error?

        sut.insert(cache, timeStamp: timeStamp) { error in
            expectedError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return expectedError
    }

    private func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "waiting for deletion to finish")
        var expectedError: Error?

        sut.deleteCachedFeed { error in
            expectedError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3.0)
        return expectedError
    }
}

private extension URL {
    static let cache: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
}
