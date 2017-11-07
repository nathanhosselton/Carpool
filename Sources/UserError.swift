import Foundation

protocol UserError: LocalizedError, CustomStringConvertible {}

extension UserError {
    var errorDescription: String? {
        return description
    }
    var failureReason: String? {
        return errorDescription
    }
}
