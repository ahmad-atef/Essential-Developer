//
//  FeedViewController.swift
//  EssentialDeveloper
//
//  Created by Ahmed Atef Ali Ahmed on 23.04.21.
//

import UIKit

struct FeedItem { }

protocol FeedLoader {
    func loadFeed(completion: @escaping (_ feedItems: [FeedItem]) -> ())
}

class FeedViewController: UIViewController {

    private let feedLoader: FeedLoader

    init(feedLoader: FeedLoader = RemoteWithLocalFallbackFeedLoader.default) {
        self.feedLoader = feedLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented") 
    }

    func loadFeed() {
        feedLoader.loadFeed { items in
            // Update UI
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadFeed()
    }
}

class Demo: UIViewController {
    let feedVC = FeedViewController()
    func test() {
        feedVC.loadFeed()
    }
}
