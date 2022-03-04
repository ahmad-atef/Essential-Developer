//
//  Date+ChangeTime.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 10.09.21.
//

import Foundation

extension Date {

    private func changeTime(byAddingDays days: Int) -> Date {
        var dateComponent = DateComponents()
        dateComponent.day = days
        return Calendar(identifier: .gregorian).date(byAdding: dateComponent, to: self)!
    }

    /// DSL for MaxAge for feed cache.
    public func minusFeedCacheMaxAge() -> Date {
        changeTime(byAddingDays: -7)
    }

    public func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
