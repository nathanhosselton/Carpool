import CoreLocation

public struct Event: Codable, Keyed {
    public var key: String!
    public let description: String
    public let owner: User
    public let time: Date
    let location: String

    public var clLocation: CLLocation? {
        return Geohash(value: location)?.location
    }
}

extension Event {
    init(json: [String: Any], key: String) throws {
        print(#function, json)
        guard let (key, json) = (json["event"] as? [String: Any])?.first else {
            throw API.Error.decode
        }
        try checkIsValidJsonType(json)
        let data = try JSONSerialization.data(withJSONObject: json)
        self = try JSONDecoder().decode(Event.self, from: data)
        self.key = key
    }
}

extension Event: Equatable {
    public static func ==(lhs: Event, rhs: Event) -> Bool {
        return lhs.key == rhs.key
    }
}

extension Event: Comparable {
    public static func <(lhs: Event, rhs: Event) -> Bool {
        return lhs.time < rhs.time
    }
}

extension Event: Hashable {
    public var hashValue: Int {
        return key.hashValue
    }
}
