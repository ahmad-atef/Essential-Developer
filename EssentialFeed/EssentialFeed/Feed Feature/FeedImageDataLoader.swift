import Foundation

public typealias FeedImageResult = Result<[ImageItem], Error>

protocol FeedImageDataLoader {
    func loadImages(completion: @escaping (FeedImageResult) -> Void)
}
