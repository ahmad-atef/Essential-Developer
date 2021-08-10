//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 17.06.21.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ object: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Instance should have been allocated, potential memory leak! 🤡", file: file, line: line)
        }
    }
}
