//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 29.04.21.
//

import Foundation

public typealias FeedLoaderResult = Result<[FeedImage], Error>

protocol FeedLoader {
    func loadFeed(completion: @escaping (FeedLoaderResult) -> Void)
}

