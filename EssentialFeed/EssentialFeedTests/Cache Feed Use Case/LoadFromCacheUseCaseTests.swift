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

        var receivedError: NSError?
        let expectation = expectation(description: "wait for completion")

        service.loadItems { result in
            guard case .failure(let error) = result else {
                XCTFail()
                preconditionFailure()
            }
            receivedError = error as NSError
            expectation.fulfill()
        }
        
        store.completeRetrievalWithError(.anyNSError)
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedError, .anyNSError)
    }

    func testLoadCommandDeliversNoImagesOnEmptyCache() {
        let (service, store) = makeSUT()

        let expectation = expectation(description: "waiting for completion")
        var receivedItems: [LocalFeedItem]?

        service.loadItems { result in
            guard case .success(let items) = result else { preconditionFailure() }
            receivedItems = items
            expectation.fulfill()
        }

        store.completeRetrievalSuccessfullyWithItems([])
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedItems, [])
    }

    func testLoadCommandShouldSuccessWhenStoreRetrievalSuccess() {
        let (service, store) = makeSUT()

        let expectation = expectation(description: "waiting for completion")
        var receivedItems: [LocalFeedItem]?

        service.loadItems { result in
            guard case .success(let items) = result else { preconditionFailure() }
            receivedItems = items
            expectation.fulfill()
        }

        let items = uniqueItems().local
        store.completeRetrievalSuccessfullyWithItems(items)
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedItems, items)
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

    private func uniqueItems() -> (model: [FeedItem], local: [LocalFeedItem]) {
        let items: [FeedItem] = [.unique, .unique]
        let localFeedItems: [LocalFeedItem] = items.map { LocalFeedItem($0) }
        return(items, localFeedItems)
    }
}
