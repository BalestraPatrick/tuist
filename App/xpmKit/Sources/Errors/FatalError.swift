import Foundation

/// Error type.
///
/// - abort: error thrown when an unexpected condition happens.
/// - bug: error thrown when a bug is found and the execution cannot continue.
/// - abortSilent: like abort but without printing anything to the user.
/// - bugSilent: like bug but without printing anything to the user.
enum ErrorType {
    case abort
    case bug
    case abortSilent
    case bugSilent
}

/// Unhandled error.
struct UnhandledError: FatalError {
    let error: Error
    var type: ErrorType { return .bugSilent }
    var description: String { return error.localizedDescription }
}

/// Fatal error protocol.
protocol FatalError: Error, CustomStringConvertible {
    /// Error type.
    var type: ErrorType { get }
}
