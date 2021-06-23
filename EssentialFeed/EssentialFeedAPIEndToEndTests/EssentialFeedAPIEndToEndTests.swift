//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Ahmed Atef Ali Ahmed on 23.06.21.
//

import XCTest
import EssentialFeed

class EssentialFeedAPIEndToEndTests: XCTestCase {
    func test_endToEndServerGETRequest_matchesFixedTestAccountData() {

        let url = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: url, client: client)

        trackForMemoryLeaks(client)
        trackForMemoryLeaks(loader)
        
        let expectation = expectation(description: "Waiting for completion")

        loader.loadFeed { result in
            switch result {
            case .success(let items):
                XCTAssertEqual(items.count, 8)

            case .failure(let error):
                XCTFail("failed with error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }
}
