//
//  FeedImage.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 01.07.21.
//

import Foundation

public typealias FeedImageResult = Result<[ImageItem], Error>

protocol FeedImage {
    func loadImages(completion: @escaping (FeedImageResult) -> Void)
}
