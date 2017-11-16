import FirebaseCommunity
import CoreLocation
import PromiseKit

public enum API {
    public enum Error: Swift.Error {
        case notAuthorized
        case noChildNode
        case noChildNodes
        case decode
        case invalidJsonType
        case emptyDescription
        case notAString
        case notYourTripToDelete
        case anonymousUsersCannotCreateTrips
        case deprecated
        case noChildName
        case eventEndTimeMustBeGreaterThanStartTime
        case locationInvalid

        /// sign-up or sign-in failed
        case signInFailed(underlyingError: Swift.Error)
    }

    /// you can still access data as an anonymous user, but you cannot create events
    public static var isCurrentUserAnonymous: Bool {
        return Auth.auth().currentUser?.isAnonymous ?? true
    }
}
