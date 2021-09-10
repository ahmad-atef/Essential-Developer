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

    func testLoadCommandDeliversCachedImagesOnLessThanSevenDaysOldCache() {
        let (service, store) = makeSUT()
        let items = uniqueItems().local
        let lessThanSevenDaysTimeStamp = Date().changeTime(byAddingDays: -7, seconds: 1)

        expect(service, toCompleteLoadingWith: .success(items)) {
            store.completeRetrievalSuccessfullyWithItems(items, timeStamp: lessThanSevenDaysTimeStamp)
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

    private func expect(_ sut: LocalFeedLoader, toCompleteLoadingWith expectedResult: LoadFeedResult, onAction action: () -> Void ) {
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

    private func uniqueItems() -> (model: [FeedItem], local: [LocalFeedItem]) {
        let items: [FeedItem] = [.unique, .unique]
        let localFeedItems: [LocalFeedItem] = items.map { LocalFeedItem($0) }
        return(items, localFeedItems)
    }
}
