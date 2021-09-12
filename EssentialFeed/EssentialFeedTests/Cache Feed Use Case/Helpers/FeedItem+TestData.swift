//
//  LocalFeedItem+mock.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 10.09.21.
//

import Foundation
import EssentialFeed

public extension FeedItem {
    static let unique = FeedItem(
        id: UUID(),
        description: nil,
        location: nil,
        imageURL: .init(string: "https://image-url.com")!)
}
