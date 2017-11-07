public struct Trip {
    let id: String
    public let event: Event
    public let pickUp: Leg
    public let dropOff: Leg
}

extension Trip: Equatable {
    public static func ==(lhs: Trip, rhs: Trip) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct Leg {
    let id: String
    public let driver: User?

    public var isClaimed: Bool {
        return driver != nil
    }
}

extension Leg: Equatable {
    public static func ==(lhs: Leg, rhs: Leg) -> Bool {
        return lhs.id == rhs.id
    }
}
