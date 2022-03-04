import Foundation

extension Date {
    private func adding(days: Int) -> Date {
        var dateComponent = DateComponents()
        dateComponent.day = days
        return Calendar(identifier: .gregorian).date(byAdding: dateComponent, to: self)!
    }

    private var feedCacheMaxAgeInDays: Int {
        return 7
    }

    /// DSL for MaxAge for feed cache.
    public func minusFeedCacheMaxAge() -> Date {
        adding(days: feedCacheMaxAgeInDays)
    }
}

extension Date {
    public func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
