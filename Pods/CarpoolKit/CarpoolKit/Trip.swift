import PromiseKit

public struct Trip: Codable, Keyed {
    var key: String!
    public let event: Event
    public let pickUp: Leg?
    public let dropOff: Leg?
}

extension Trip: Equatable {
    public static func ==(lhs: Trip, rhs: Trip) -> Bool {
        return lhs.key == rhs.key
    }
}

extension Trip: Comparable {
    public static func <(lhs: Trip, rhs: Trip) -> Bool {
        return lhs.event.time < rhs.event.time
    }
}

extension Trip: Hashable {
    public var hashValue: Int {
        return key.hashValue
    }
}

extension Trip {
    static func make(key: String, json: [String: Any]) -> Promise<Trip> {
        do {
            func get(key: String) -> User? {
                guard let json = json[key] as? [String: String] else { return nil }
                guard let item = json.first else { return nil }
                return User(key: item.key, name: item.value)
            }

            //guard let owner = get(key: "owner") else { throw API.Error.decode }
            let dropOff = get(key: "dropOff")
            let pickUp = get(key: "pickUp")
            let event = try Event(json: json, key: "event")

            return Promise(value: Trip(key: key, event: event, pickUp: pickUp.map(Leg.init), dropOff: dropOff.map(Leg.init)))
        } catch {
            return Promise(error: error)
        }
    }
}
