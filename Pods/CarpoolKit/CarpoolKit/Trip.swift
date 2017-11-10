import FirebaseCommunity
import PromiseKit

public struct Trip: Codable, Keyed {
    var key: String!
    public let event: Event

    /// the leg for dropping off children at the event
    public let dropOff: Leg?

    /// the leg for picking up children from the event
    public let pickUp: Leg?

    enum CodingKeys: String, CodingKey {
        case key, event, pickUp, dropOff
        case _children = "children"
    }

    public var children: [Child] {
        return _children ?? []
    }
    let _children: [Child]?
}

extension Trip: Equatable {
    public static func ==(lhs: Trip, rhs: Trip) -> Bool {
        return lhs.key == rhs.key
    }
}

extension Trip: Comparable {
    public static func <(lhs: Trip, rhs: Trip) -> Bool {
        return lhs.event.time > rhs.event.time
    }
}

extension Trip: Hashable {
    public var hashValue: Int {
        return key.hashValue
    }
}

extension Trip {
    static func make(key: String, json: [String: Any]) -> Promise<Trip> {
        func getLeg(key: String) -> Promise<User?> {
            guard let json = json[key] as? [String: String] else { return Promise(value: nil) }
            guard let item = json.first else { return Promise(value: nil) }
            return API.fetchUser(id: item.key).then(on: zalgo){ $0 }
        }

        let dropOff = getLeg(key: "dropOff")
        let pickUp = getLeg(key: "pickUp")
        let event = Event.make(key: "event", json: json)

        return firstly {
            when(fulfilled: dropOff, pickUp, event)
        }.then { dropOff, pickUp, event in
            Trip(key: key, event: event, dropOff: dropOff.map(Leg.init), pickUp: pickUp.map(Leg.init), _children: [])
        }
    }
}

extension Trip: CustomDebugStringConvertible {
    public var debugDescription: String {
        return key
    }
}
