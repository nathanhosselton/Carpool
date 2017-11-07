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
