import FirebaseCommunity
import CoreLocation

func checkIsValidJsonType(_ any: Any) throws {
    if let _ = any as? NSNumber {
        throw API.Error.invalidJsonType
    }
    if let _ = any as? NSString {
        throw API.Error.invalidJsonType
    }
    if any is NSNull {
        throw API.Error.invalidJsonType
    }
}

func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left[k] = v
    }
}

public enum Result<T> {
    case success(T)
    case failure(Swift.Error)
}

protocol Keyed {
    var key: String! { get set }
}

public extension String {
    func chuzzled() -> String? {
        let rv = trimmingCharacters(in: .whitespacesAndNewlines)
        return rv.isEmpty ? nil : rv
    }
}

/// for automatically stopping observing
class Reaper: UIView {
    //FIXME doesn't work unless we get students to do [unowned self]
    //TODO potentially swizzling instances of the VC for didMove(toParentController:) would work

    var ref: DatabaseReference!
    var observer: DatabaseHandle!

    deinit {
        ref.removeObserver(withHandle: observer)
    }
}

public extension Comparable {
    func clamped(to limits: Range<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

