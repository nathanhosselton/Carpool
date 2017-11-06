public struct Trip {
    let id: String
    public let event: Event
    public let pickUp: Leg
    public let dropOff: Leg
}

public struct Leg {
    let id: String
    public let driver: User?

    public var isClaimed: Bool {
        return driver != nil
    }
}
