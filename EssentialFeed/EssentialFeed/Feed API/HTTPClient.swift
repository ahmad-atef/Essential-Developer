//
//  File.swift
//  EssentialFeed
//
//  Created by Ahmed Atef Ali Ahmed on 04.06.21.
//

import Foundation

public typealias ClientResult = Result<(Data,HTTPURLResponse), Error>

public protocol HTTPClient {
    func request(from url: URL, completion: @escaping (ClientResult) -> Void)
}
