import XCTest
import EssentialFeed

class CodableFeedStoreTests: XCTestCase {

    class CodableFeedStore {
        func retrieve(completion: @escaping (RetrieveFeedResult) -> Void) {
            completion(.empty)
        }
    }

    // retrieve from empty cache delivers empty result
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
}
