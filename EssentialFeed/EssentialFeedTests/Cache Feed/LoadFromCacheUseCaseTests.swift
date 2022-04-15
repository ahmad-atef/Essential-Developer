import XCTest
import EssentialFeed

// Store can do the following operations:
// `insert`
// `delete`
// `retrieve`

// Service have two commands / API
// - loadItems
// - saveItems


final class LoadFromCacheUseCaseTests: XCTestCase {

    func testLoadRequestInsertOperation() {
        let (service, store) = makeSUT()

        service.loadItems { _ in }

        XCTAssertEqual(store.operations, [.retrieval])
    }

    func testLoadCommandFailsWhenStoreFailsToRetrieve() {
        let (service, store) = makeSUT()
        expect(service, toCompleteLoadingWith: .failure(NSError.anyNSError)) {
            store.completeRetrievalWithError(NSError.anyNSError)
        }
    }

    func testLoadCommandDeliversNoImagesOnEmptyCache() {
        let (service, store) = makeSUT()
        expect(service, toCompleteLoadingWith: .success([])) {
            store.completeRetrievalSuccessfullyWithItems([])
        }
    }

    func testLoadCommandShouldSuccessWhenStoreRetrievalSuccess() {
        let (service, store) = makeSUT()
        let items = uniqueItems().local

        expect(service, toCompleteLoadingWith: .success(items)) {
            store.completeRetrievalSuccessfullyWithItems(items)
        }
    }

    func testLoadCommandDeliversCachedImagesSuccessfullyOnValidCache() {
        let (service, store) = makeSUT()
        let items = uniqueItems().local
        let validTimeStamp = Date().minusFeedCacheMaxAge().adding(seconds: 1)

        expect(service, toCompleteLoadingWith: .success(items)) {
            store.completeRetrievalSuccessfullyWithItems(items, timeStamp: validTimeStamp)
        }
    }

    func testLoadCommandDeliversNoImagesOnJustExpiredCache() {
        let items = uniqueItems().local
        let expiredTimeStamp = Date().minusFeedCacheMaxAge()
        let (service, store) = makeSUT()

        expect(service, toCompleteLoadingWith: .success([])) {
            store.completeRetrievalSuccessfullyWithItems(items, timeStamp: expiredTimeStamp)
        }
    }

    func testLoadCommandDeliversNoImagesOnExpiredCache() {
        let (service, store) = makeSUT()
        let items = uniqueItems().local

        expect(service, toCompleteLoadingWith: .success([])) {
            store.completeRetrievalSuccessfullyWithItems(items, timeStamp: Date.distantPast)
        }
    }
}

extension LoadFromCacheUseCaseTests {
    private func makeSUT(currentDate: Date  = .init(), _ file: StaticString = #filePath, line: UInt = #line) ->(localFeedLoader: LocalFeedLoader, store: SpyFeedStore) {
        let store = SpyFeedStore()
        let sut = LocalFeedLoader(store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteLoadingWith expectedResult: LocalFeedResult, onAction action: () -> Void ) {
        let expectation = expectation(description: "waiting for completion")
        sut.loadItems { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedItems), .success(let expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems)
            case (.failure(let receivedError), .failure(let expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError)
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead")
            }
            expectation.fulfill()
        }

        action()
        wait(for: [expectation], timeout: 1.0)
    }

    private func uniqueItems() -> (model: [FeedImage], local: [LocalFeedImage]) {
        let items: [FeedImage] = [.unique, .unique]
        let localFeedItems: [LocalFeedImage] = items.map { LocalFeedImage($0) }
        return(items, localFeedItems)
    }
}
