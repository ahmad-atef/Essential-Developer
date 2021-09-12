//
//  Date+ChangeTime.swift
//  EssentialFeedTests
//
//  Created by Ahmed Atef Ali Ahmed on 10.09.21.
//

import Foundation

extension Date {
    public func changeTime(byAddingDays days: Int, seconds: Int) -> Date {
        var dateComponent = DateComponents()
        dateComponent.day = days
        dateComponent.second = seconds

        return Calendar(identifier: .gregorian).date(byAdding: dateComponent, to: self)!
    }
}
