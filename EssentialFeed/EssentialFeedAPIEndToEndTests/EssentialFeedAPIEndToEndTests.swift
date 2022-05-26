//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Ahmed Atef Ali Ahmed on 23.06.21.
//

import XCTest
import EssentialFeed

final class EssentialFeedAPIEndToEndTests: XCTestCase {
    func test_endToEndServerGETRequest_matchesFixedTestAccountData() {

        let url = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient(session: .init(configuration: .ephemeral))
        let loader = RemoteFeedLoader(url: url, client: client)

        trackForMemoryLeaks(client)
        trackForMemoryLeaks(loader)
        
        let expectation = expectation(description: "Waiting for completion")

        loader.loadFeed { result in
            switch result {
            case .success(let items):
                XCTAssertEqual(items.count, 8)

                items.enumerated().forEach { index, item in
                    XCTAssertEqual(item.id, self.expectedFeedItem(at: index).id)
                    XCTAssertEqual(item.description, self.expectedFeedItem(at: index).description)
                    XCTAssertEqual(item.imageURL, self.expectedFeedItem(at: index).imageURL)
                    XCTAssertEqual(item.location, self.expectedFeedItem(at: index).location)
                }

            case .failure(let error):
                XCTFail("failed with error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    private func expectedFeedItem(at index: Int, file: StaticString = #filePath, line: UInt = #line) -> FeedImage {
        return [
            FeedImage(
                id: .init(uuidString: "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6")!,
                description: "Description 1",
                location: "Location 1",
                imageURL: URL(string: "https://url-1.com")!
            ),
            FeedImage(
                id: .init(uuidString: "BA298A85-6275-48D3-8315-9C8F7C1CD109")!,
                description: nil,
                location: "Location 2",
                imageURL: URL(string: "https://url-2.com")!
            ),
            FeedImage(
                id: .init(uuidString: "5A0D45B3-8E26-4385-8C5D-213E160A5E3C")!,
                description: "Description 3",
                location: nil,
                imageURL: URL(string: "https://url-3.com")!
            ),
            FeedImage(
                id: .init(uuidString: "FF0ECFE2-2879-403F-8DBE-A83B4010B340")!,
                description: nil,
                location: nil,
                imageURL: URL(string: "https://url-4.com")!
            ),
            FeedImage(
                id: .init(uuidString: "DC97EF5E-2CC9-4905-A8AD-3C351C311001")!,
                description: "Description 5",
                location: "Location 5",
                imageURL: URL(string: "https://url-5.com")!
            ),
            FeedImage(
                id: .init(uuidString: "557D87F1-25D3-4D77-82E9-364B2ED9CB30")!,
                description: "Description 6",
                location: "Location 6",
                imageURL: URL(string: "https://url-6.com")!
            ),
            FeedImage(
                id: .init(uuidString: "A83284EF-C2DF-415D-AB73-2A9B8B04950B")!,
                description: "Description 7",
                location: "Location 7",
                imageURL: URL(string: "https://url-7.com")!
            ),
            FeedImage(
                id: .init(uuidString: "F79BD7F8-063F-46E2-8147-A67635C3BB01")!,
                description: "Description 8",
                location: "Location 8",
                imageURL: URL(string: "https://url-8.com")!
            )
        ][index]
    }

}
