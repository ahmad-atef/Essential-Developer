//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Ahmad Atef on 20220510...
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {

    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty)
    }
    @discardableResult
    func insert(_ cache: [LocalFeedImage], timeStamp: Date, to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Waiting for cache insertion")
        var expectedError: Error?

        sut.insert(cache, timeStamp: timeStamp) { error in
            expectedError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return expectedError
    }

    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "waiting for deletion to finish")
        var expectedError: Error?

        sut.deleteCachedFeed { error in
            expectedError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3.0)
        return expectedError
    }

    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
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
}
