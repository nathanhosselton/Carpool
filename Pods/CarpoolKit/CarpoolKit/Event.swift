import CoreLocation
import PromiseKit

public struct Event: Codable, Keyed {
    public var key: String!
    public let description: String
    public private(set) var owner: User
    public let time: Date
    public let endTime: Date?
    let location: String?

    public var clLocation: CLLocation? {
        return location.flatMap(Geohash.init(value:))?.location
    }
}

extension Event {
    init(json: [String: Any], key: String) throws {
        guard let (key, json) = (json["event"] as? [String: Any])?.first else {
            throw API.Error.decode
        }
        try checkIsValidJsonType(json)
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        self = try decoder.decode(Event.self, from: data)
        self.key = key
    }

    static func make(key: String, json: [String: Any]) -> Promise<Event> {
        do {
            var event = try Event(json: json, key: key)
            if let uid = (json["owner"] as? [String: String])?.first?.key {
                return firstly {
                    API.fetchUser(id: uid)
                }.then { user -> Event in
                    event.owner = user
                    return event
                }
            } else {
                return Promise(value: event)
            }
        } catch {
            return Promise(error: error)
        }
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
