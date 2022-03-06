internal final class FeedCachePolicy {
    private init() { }

    private static let calendar = Calendar(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int { 7 }

    internal static func validate(_ timeStamp: Date, against date: Date) -> Bool {
        guard let daysDiff = calendar.dateComponents([.day], from: timeStamp, to: date).day else { return false }
        return daysDiff < maxCacheAgeInDays
    }
}
 
