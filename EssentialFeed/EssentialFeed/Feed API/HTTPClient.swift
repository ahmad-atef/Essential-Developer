import Foundation

public typealias ClientResult = Result<(Data,HTTPURLResponse), Error>

public protocol HTTPClient {
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (ClientResult) -> Void)
}
