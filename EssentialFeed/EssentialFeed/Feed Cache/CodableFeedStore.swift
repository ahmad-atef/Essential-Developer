//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Ahmad Atef on 20220410...
//

import Foundation

public class CodableFeedStore: FeedStore {

    private struct Cache: Codable {
        let items: [CodableLocalFeedImage]
        let timeStamp: Date

        var localFeed: [LocalFeedImage] { items.map{ $0.localFeedImage } }
    }

    /// `CodableLocalFeedImage` is a type to do internal implementations/complications to read/write to disk from/to `CodableFeedStore`, e.g: all properties must be Codable like Sting, Int to be able to save/retrieve from/to disk.
    private struct CodableLocalFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let imageURL: URL

        init(_ localFeedImage: LocalFeedImage) {
            self.id = localFeedImage.id
            self.description = localFeedImage.description
            self.location = localFeedImage.location
            self.imageURL = localFeedImage.imageURL
        }

        var localFeedImage: LocalFeedImage {
            .init(id: id, description: description, location: location, imageURL: imageURL)
        }
    }

    private let storeURL: URL

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    public func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        do {
            let encoder = JSONEncoder()
            let cache = Cache(items: items.map(CodableLocalFeedImage.init), timeStamp: timeStamp)
            let encodedData = try encoder.encode(cache)
            try encodedData.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    public func retrieve(completion: @escaping (RetrieveFeedResult) -> Void) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        let decoder = JSONDecoder()
        do {
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(cache.localFeed, cache.timeStamp))
        } catch {
            completion(.failure(error))
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

